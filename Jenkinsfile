pipeline {
  agent any

  parameters {
    string(name: 'AWS_REGION', defaultValue: 'ap-south-1', description: 'AWS region')
    string(name: 'ECR_REPO', defaultValue: 'gl-capstone-project-pan-repo', description: 'ECR repository name')
    string(name: 'CLUSTER_NAME', defaultValue: 'capstone-project-eks-cluster', description: 'EKS cluster name')
  }

  options {
    timestamps()
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('SAST & Manifest Lint') {
      steps {
        sh '''
          set +e # Don't fail on errors for informational scans
          echo "Running Trivy filesystem scan (HIGH,CRITICAL) on repo..."
          # Prepare local cache dir for Trivy DB to speed up
          cachePath="${WORKSPACE}/.trivy-cache"
          mkdir -p "$cachePath"
          docker run --rm -v "${WORKSPACE}:/repo" -v "${cachePath}:/root/.cache/trivy" -w /repo aquasec/trivy:0.50.0 fs --no-progress --scanners vuln --severity HIGH,CRITICAL --timeout 15m --exit-code 0 .
          if [ $? -ne 0 ]; then echo "Trivy filesystem scan returned non-zero; proceeding (informational only)."; fi

          if [ -d "manifests" ]; then
            echo "Linting Kubernetes manifests with kubeval..."
            docker run --rm -v "${WORKSPACE}/manifests:/manifests" cytopia/kubeval:latest -d /manifests
            echo "Running kube-linter for richer checks..."
            docker run --rm -v "${WORKSPACE}/manifests:/manifests" stackrox/kube-linter:v0.6.8 lint /manifests
          fi
        '''
      }
    }

    stage('Tools Versions') {
      steps {
        sh '''
          set +e # Don't fail on errors
          aws --version
          kubectl version --client
          docker --version
        '''
      }
    }

    stage('AWS Identity Check') {
      steps {
        sh '''
          echo "Checking AWS identity (using IAM Role)..."
          aws sts get-caller-identity
        '''
      }
    }

    stage('Docker Build and Push to ECR') {
      environment {
        IMAGE_TAG = "${env.GIT_COMMIT?.take(7) ?: env.BUILD_NUMBER}"
      }
      steps {
        sh '''
          set -e
          ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
          ECR_REG="$ACCOUNT_ID.dkr.ecr.${AWS_REGION}.amazonaws.com"
          REPO_URL="$ECR_REG/${ECR_REPO}"

          echo "ECR Registry: $ECR_REG"
          echo "Repo URL:     $REPO_URL"
          
          # Clear any stale auth (ignore errors)
          docker logout "$ECR_REG" 2>/dev/null || true
          
          # ECR Login
          loginOk=false
          for i in 1 2; do
            pwd=$(aws ecr get-login-password --region "${AWS_REGION}")
            if [ -z "$pwd" ]; then echo "Empty ECR password"; continue; fi
            echo "$pwd" | docker login --username AWS --password-stdin "$ECR_REG"
            if [ $? -eq 0 ]; then loginOk=true; break; fi
            sleep 3
          done
          if [ "$loginOk" = false ]; then echo "ECR login failed after retries"; exit 1; fi

          # Compute image tag
          if [ -n "${GIT_COMMIT}" ] && [ ${#GIT_COMMIT} -ge 7 ]; then TAG="${GIT_COMMIT:0:7}"; else TAG="${BUILD_NUMBER}"; fi
          localTag="${ECR_REPO}:${TAG}"
          remoteTag="${REPO_URL}:${TAG}"

          # Build and push
          docker build -t "$localTag" .
          docker tag "$localTag" "$remoteTag"
          echo "Pushing image to ECR..."
          docker push "$remoteTag"

          # Scan pushed image
          echo "Scanning pushed image in ECR with Trivy (HIGH,CRITICAL) [informational only]..."
          ecrPwd=$(aws ecr get-login-password --region "${AWS_REGION}")
          if [ -z "$ecrPwd" ]; then echo "Failed to obtain ECR password for Trivy auth"; exit 1; fi
          cachePath="${WORKSPACE}/.trivy-cache"
          mkdir -p "$cachePath"
          docker run --rm -v "${cachePath}:/root/.cache/trivy" aquasec/trivy:0.50.0 image --no-progress --scanners vuln --severity HIGH,CRITICAL --timeout 15m --exit-code 0 --username AWS --password "$ecrPwd" "$remoteTag"
          if [ $? -ne 0 ]; then echo "Trivy remote image scan returned non-zero; proceeding (informational only)."; fi
        '''
      }
    }

    stage('Deploy to EKS') {
      when { expression { return fileExists('manifests') } }
      steps {
        sh '''
          set -e
          # Configure kubectl
          aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${AWS_REGION}"
          aws eks wait cluster-active --name "${CLUSTER_NAME}" --region "${AWS_REGION}"

          # Deploy manifests
          if [ -f 'manifests/namespace.yaml' ]; then kubectl apply -f manifests/namespace.yaml; fi
          if [ -f 'manifests/configmap.yaml' ]; then kubectl apply -f manifests/configmap.yaml; fi
          if [ -f 'manifests/secret.yaml' ]; then kubectl apply -f manifests/secret.yaml; fi
          kubectl apply -f manifests/deployment.yaml

          # Service deployment
          svcClassic='manifests/service-classic.yaml'
          svcNlb='manifests/service-nlb.yaml'
          created=false
          if [ -f "$svcClassic" ]; then
            echo 'Applying Service (Classic ELB attempt)...'
            kubectl apply -f "$svcClassic"
            # Wait up to ~6 minutes for ELB hostname
            deadline=$(date -d "+6 minutes" +%s 2>/dev/null || date -v+6M +%s)
            while [ "$created" = false ] && [ "$(date +%s)" -lt "$deadline" ]; do
              sleep 15
              svcHost=$(kubectl get svc -n app nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
              if [ -n "$svcHost" ]; then created=true; echo "Service ELB hostname: $svcHost"; fi
            done
          fi

          if [ "$created" = false ] && [ -f "$svcNlb" ]; then
            echo 'Classic ELB not ready/unsupported. Falling back to NLB...'
            kubectl apply -f "$svcNlb"
            deadline=$(date -d "+6 minutes" +%s 2>/dev/null || date -v+6M +%s)
            while [ "$(date +%s)" -lt "$deadline" ]; do
              sleep 15
              svcHost=$(kubectl get svc -n app nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
              if [ -n "$svcHost" ]; then echo "Service NLB hostname: $svcHost"; break; fi
            done
          fi
        '''
      }
    }

    stage('Rollout ECR Image') {
      when {
        allOf {
          expression { return params.ECR_REPO?.trim() }
          expression { return fileExists('manifests') }
        }
      }
      steps {
        sh '''
          set -e
          ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
          REPO_URL="$ACCOUNT_ID.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"
          if [ -n "${GIT_COMMIT}" ] && [ ${#GIT_COMMIT} -ge 7 ]; then TAG="${GIT_COMMIT:0:7}"; else TAG="${BUILD_NUMBER}"; fi
          remoteTag="${REPO_URL}:${TAG}"
          
          kubectl set image -n app deployment/nginx-deployment nginx=$remoteTag
          # Wait up to 5 minutes for rollout
          if ! kubectl rollout status -n app deployment/nginx-deployment --timeout=5m; then
            echo "Rollout status timed out - collecting diagnostics"
            kubectl get deployment -n app nginx-deployment -o wide
            kubectl describe deployment -n app nginx-deployment
            kubectl get rs -n app -o wide
            kubectl get pods -n app -o wide
            kubectl describe pods -n app
            kubectl get events --sort-by=.lastTimestamp | tail -n 100
            exit 1 # Fail the stage
          fi
        '''
      }
    }

    stage('DAST - ZAP Baseline') {
      steps {
        sh '''
          set +e # Don't fail on errors for informational scans
          aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${AWS_REGION}"
          svcHost=$(kubectl get svc -n app nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
          if [ -z "$svcHost" ]; then echo "Service hostname not ready, skipping ZAP"; exit 0; fi
          url="http://$svcHost"

          # Pre-pull ZAP image
          zapImageGhcr="ghcr.io/zaproxy/zaproxy:stable"
          zapImageHub="owasp/zap2docker-stable"
          pulled=false
          for img in "$zapImageGhcr" "$zapImageHub"; do
            for i in 1 2; do
              echo "Pulling ZAP image: $img (attempt $i)"
              docker pull "$img"
              if [ $? -eq 0 ]; then pulled=true; zapImage="$img"; break; fi
              sleep 3
            done
            if [ "$pulled" = true ]; then break; fi
          done

          if [ "$pulled" = false ]; then
            echo "Could not pull any ZAP image; skipping ZAP baseline (non-blocking)."
            exit 0
          fi

          # Prepare writable artifacts directory
          artDir="${WORKSPACE}/zap-artifacts"
          mkdir -p "$artDir"

          echo "Running ZAP Baseline scan against $url using $zapImage"
          docker run --rm -u 0:0 -v "${artDir}:/zap/wrk" -t "$zapImage" zap-baseline.py -t "$url" -r zap.html
          if [ $? -ne 0 ]; then echo "ZAP baseline returned non-zero. Proceeding (non-blocking)."; fi
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'zap-artifacts/zap.html', allowEmptyArchive: true
        }
      }
    }
  }

  post {
    always {
      echo 'Pipeline finished.'
    }
  }
}
