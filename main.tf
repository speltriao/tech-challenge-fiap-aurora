name: Deploy to AWS

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-session-token: ${{ secrets.AWS_SESSION_TOKEN }}
          aws-region: us-east-1

      - name: Terraform Init
        run: terraform init

      - name: Check if RDS Cluster Exists
        id: check_rds
        run: |
          cluster_status=$(aws rds describe-db-clusters --db-cluster-identifier galega-aurora --query 'DBClusters[0].Status' --output text || echo "not found")
          if [ "$cluster_status" != "not found" ]; then
            echo "RDS Cluster exists."
            echo "RDS_EXISTS=true" >> $GITHUB_ENV
          else
            echo "RDS Cluster does not exist."
            echo "RDS_EXISTS=false" >> $GITHUB_ENV
          fi

      - name: Terraform Plan
        env:
          TF_LOG: DEBUG
          TF_VAR_db_master_username: ${{ secrets.DB_MASTER_USERNAME }}
          TF_VAR_db_master_password: ${{ secrets.DB_MASTER_PASSWORD }}
        run: terraform plan

      - name: Terraform Apply
        if: env.RDS_EXISTS == 'false'
        env:
          TF_VAR_db_master_username: ${{ secrets.DB_MASTER_USERNAME }}
          TF_VAR_db_master_password: ${{ secrets.DB_MASTER_PASSWORD }}
        run: terraform apply -auto-approve

      - name: Terraform Output
        id: terraform_output
        run: |
          echo "Debugging Terraform output..."
          terraform output -raw endpoint
          echo "ENDPOINT=$(terraform output -raw endpoint)" >> $GITHUB_ENV

      - name: Install PostgreSQL Client
        run: sudo apt-get install -y postgresql-client

      - name: Check if Database Exists
        id: check_db
        env:
          PGHOST: ${{ env.ENDPOINT }}
          PGUSER: ${{ secrets.DB_MASTER_USERNAME }}
          PGPASSWORD: ${{ secrets.DB_MASTER_PASSWORD }}
        run: |
          if psql -h $PGHOST -U $PGUSER -lqt | cut -d \| -f 1 | grep -qw galega_burguer; then
            echo "Database exists."
            echo "DB_EXISTS=true" >> $GITHUB_ENV
          else
            echo "Database does not exist."
            echo "DB_EXISTS=false" >> $GITHUB_ENV
          fi

      - name: Create Database (if not exists)
        if: env.DB_EXISTS == 'false'
        env:
          PGHOST: ${{ env.ENDPOINT }}
          PGUSER: ${{ secrets.DB_MASTER_USERNAME }}
          PGPASSWORD: ${{ secrets.DB_MASTER_PASSWORD }}
        run: |
          psql -h $PGHOST -U $PGUSER -c "CREATE DATABASE galega_burguer;"

      - name: Run SQL Script
        env:
          PGHOST: ${{ env.ENDPOINT }}
          PGUSER: ${{ secrets.DB_MASTER_USERNAME }}
          PGPASSWORD: ${{ secrets.DB_MASTER_PASSWORD }}
          PGDATABASE: galega_burguer
        run: |
          psql -h $PGHOST -U $PGUSER -d $PGDATABASE -f scripts/schema.sql
