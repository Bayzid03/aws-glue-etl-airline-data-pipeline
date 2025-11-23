# ✈️ AWS Glue ETL Airline Data Pipeline

> **Event-driven serverless data pipeline for flight delay analytics with automated orchestration and monitoring**

[![AWS Glue](https://img.shields.io/badge/AWS%20Glue-ETL-FF9900?style=flat-square&logo=amazon-aws)](https://aws.amazon.com/glue/)
[![Step Functions](https://img.shields.io/badge/Step%20Functions-Orchestration-FF9900?style=flat-square&logo=amazon-aws)](https://aws.amazon.com/step-functions/)
[![Redshift](https://img.shields.io/badge/Redshift-Data%20Warehouse-FF9900?style=flat-square&logo=amazon-aws)](https://aws.amazon.com/redshift/)
[![EventBridge](https://img.shields.io/badge/EventBridge-Event%20Bus-FF9900?style=flat-square&logo=amazon-aws)](https://aws.amazon.com/eventbridge/)

## 🎯 Overview

An **event-driven ETL pipeline** that automatically processes daily airline flight data, enriches it with airport dimensions, and loads delay analytics into Redshift. Built with AWS serverless services featuring crawler orchestration, PySpark transformations, and SNS-based monitoring.

### ✨ Key Features

- **⚡ Event-Driven Architecture** - S3 uploads trigger automated pipeline execution
- **🔄 Step Functions Orchestration** - Multi-step workflow with error handling
- **🤖 Glue Crawlers** - Auto-catalog schema discovery (3 crawlers)
- **🔧 PySpark ETL** - Complex joins and transformations for delay analysis
- **💾 Redshift Analytics** - Denormalized fact table for BI queries
- **📧 SNS Notifications** - Success/failure alerts for pipeline monitoring
- **🗂️ Hive Partitioning** - Daily partitioned data for efficient processing

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                   DATA SOURCE                                │
├──────────────────────────────────────────────────────────────┤
│  📁 Daily Flight Data (CSV)                                 │
│  • Hive-style partitions: year=YYYY/month=MM/day=DD/        │
│  • Fields: carrier, origin/dest airports, delays            │
│  📍 Airport Dimension (CSV)                                  │
│  • Static reference: airport_id, city, state, name          │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│                   INGESTION LAYER                            │
├──────────────────────────────────────────────────────────────┤
│  📦 Amazon S3 Bucket                                        │
│  • Folder: dim/airports.csv (dimension)                     │
│  • Folder: daily_flights/ (partitioned fact data)           │
│  • EventBridge notifications enabled                         │
└──────────────────────────────────────────────────────────────┘
                            ↓
                   🔔 S3 Object Created Event
                            ↓
┌──────────────────────────────────────────────────────────────┤
│                   EVENT DETECTION                            │
├──────────────────────────────────────────────────────────────┤
│  📡 Amazon EventBridge Rule                                 │
│  • Event Pattern: Object Created (*.csv suffix)             │
│  • Target: Step Function state machine                      │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│               ORCHESTRATION LAYER                            │
├──────────────────────────────────────────────────────────────┤
│  🔄 AWS Step Functions State Machine                        │
│                                                              │
│  1. StartCrawler                                             │
│     └─→ Trigger: flights-data-crawler                       │
│                                                              │
│  2. GetCrawler (polling loop)                                │
│     └─→ Check crawler state                                 │
│                                                              │
│  3. Is_Running? (Choice state)                               │
│     ├─→ RUNNING → Wait 5 seconds → GetCrawler               │
│     └─→ READY → Glue StartJobRun                            │
│                                                              │
│  4. Glue StartJobRun (.sync)                                 │
│     ├─→ Job: airline_data_ingestion                         │
│     ├─→ Success → Glue_Job_Status                           │
│     └─→ Failure → Failed_Notification (SNS)                 │
│                                                              │
│  5. Glue_Job_Status (Choice state)                           │
│     ├─→ SUCCEEDED → Success_Notification                    │
│     └─→ FAILED → Failed_Notification                        │
└──────────────────────────────────────────────────────────────┘
```

## 📊 Step Function Workflow

![Step Function Workflow] <img width="569" height="470" alt="image" src="https://github.com/user-attachments/assets/555b8187-f050-4e4c-b0f9-1c628978cc5c" />

*Automated orchestration with crawler polling, job execution, and SNS notifications*

---

## 🔧 Glue ETL Job Architecture

![Glue ETL Job] <img width="567" height="647" alt="image" src="https://github.com/user-attachments/assets/ae5bbf98-d014-4efa-a2ac-7b32e6563b27" />

*PySpark transformation flow: Filter → Join → Enrich → Load to Redshift*

---

## 🔄 ETL Process Flow

```
┌──────────────────────────────────────────────────────────────┐
│               DATA CATALOGING                                │
├──────────────────────────────────────────────────────────────┤
│  🤖 AWS Glue Crawlers (3 total)                             │
│                                                              │
│  1. flights-data-crawler (S3)                                │
│     └─→ Catalogs daily_flights/ partitions                  │
│                                                              │
│  2. airline_dim_crawler (Redshift)                           │
│     └─→ Catalogs airports_dim table                         │
│                                                              │
│  3. airline_fact_crawler (Redshift)                          │
│     └─→ Catalogs daily_flights_fact table                   │
│                                                              │
│  📚 Glue Data Catalog: airlines-table-catalog                │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│               TRANSFORMATION LAYER                           │
├──────────────────────────────────────────────────────────────┤
│  ⚡ AWS Glue ETL Job (PySpark)                              │
│                                                              │
│  Step 1: Extract                                             │
│  • Read daily_flights from Glue Catalog                     │
│  • Read airports_dim from Redshift (via JDBC)               │
│                                                              │
│  Step 2: Filter                                              │
│  • Identify delayed flights (depdelay > 60 min)             │
│                                                              │
│  Step 3: Enrich - Departure Join                             │
│  • Join flights with airports_dim on originairportid        │
│  • Extract: dep_city, dep_airport, dep_state                │
│                                                              │
│  Step 4: Enrich - Arrival Join                               │
│  • Join with airports_dim on destairportid                  │
│  • Extract: arr_city, arr_airport, arr_state                │
│                                                              │
│  Step 5: Transform Schema                                    │
│  • ApplyMapping for Redshift compatibility                  │
│  • Cast data types (VARCHAR, BIGINT)                        │
│                                                              │
│  Step 6: Load                                                │
│  • Write to Redshift: airlines.daily_flights_fact           │
│  • Use S3 temp directory for staging                        │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│               DATA WAREHOUSE                                 │
├──────────────────────────────────────────────────────────────┤
│  🗄️ Amazon Redshift Cluster                                │
│                                                              │
│  Schema: airlines                                            │
│                                                              │
│  • airports_dim (dimension table)                            │
│    - airport_id, city, state, name                          │
│    - 300+ U.S. airports                                      │
│                                                              │
│  • daily_flights_fact (fact table - denormalized)           │
│    - carrier, dep_delay, arr_delay                          │
│    - dep_city, dep_airport, dep_state                       │
│    - arr_city, arr_airport, arr_state                       │
│    - Pre-joined for fast BI queries                         │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│               MONITORING & NOTIFICATIONS                     │
├──────────────────────────────────────────────────────────────┤
│  📧 Amazon SNS Topic                                        │
│  • Success notifications: Job completed                     │
│  • Failure notifications: Error details + logs              │
│  • Email/SMS alerts to data team                            │
└──────────────────────────────────────────────────────────────┘
```

## 🛠️ Technical Stack

### **Core AWS Services**
- **⚡ AWS Glue** - Serverless ETL with PySpark
- **🔄 AWS Step Functions** - Workflow orchestration with state machine
- **📡 Amazon EventBridge** - Event-driven pipeline triggers
- **🗄️ Amazon Redshift** - Petabyte-scale data warehouse
- **📦 Amazon S3** - Data lake storage with partitioning
- **📧 Amazon SNS** - Real-time notifications

### **Data Processing**
- **🐍 PySpark** - Distributed data transformations
- **🤖 Glue Crawlers** - Auto-schema discovery
- **📚 Glue Data Catalog** - Centralized metadata repository
- **🔗 JDBC Connection** - Glue ↔ Redshift integration

### **Infrastructure**
- **🔐 IAM Roles** - Secure service permissions
- **🌐 VPC Configuration** - Network isolation with S3 endpoint
- **🔒 Security Groups** - Redshift port access control

## 📊 Data Model

### **Dimension Table: airports_dim**
```sql
CREATE TABLE airlines.airports_dim (
    airport_id BIGINT,
    city VARCHAR(100),
    state VARCHAR(100),
    name VARCHAR(200)
);
-- 300+ U.S. airports with metadata
```

### **Fact Table: daily_flights_fact (Denormalized)**
```sql
CREATE TABLE airlines.daily_flights_fact (
    carrier VARCHAR(10),
    dep_airport VARCHAR(200),
    arr_airport VARCHAR(200),
    dep_city VARCHAR(100),
    arr_city VARCHAR(100),
    dep_state VARCHAR(100),
    arr_state VARCHAR(100),
    dep_delay BIGINT,
    arr_delay BIGINT
);
```

**Design Note:** The fact table is **denormalized** (pre-joined with dimension) to eliminate repeated joins during BI queries, improving query performance by 10-50x.

## 🚀 Quick Start

### Prerequisites
- AWS account with appropriate permissions
- AWS CLI configured
- S3 bucket with EventBridge notifications enabled
- Redshift cluster with VPC and S3 endpoint configured

### Setup Instructions

**1. Create S3 Bucket & Upload Data**
```bash
# Create bucket
aws s3 mb s3://airline-data-landing-zn

# Upload dimension data
aws s3 cp airports.csv s3://airline-data-landing-zn/dim/

# Upload daily flight data (partitioned)
aws s3 cp daily_flights/ s3://airline-data-landing-zn/daily_flights/ --recursive

# Enable EventBridge notifications
aws s3api put-bucket-notification-configuration \
  --bucket airline-data-landing-zn \
  --notification-configuration file://s3-notification.json
```

**2. Create Redshift Cluster & Tables**
```sql
-- Create schema
CREATE SCHEMA airlines;

-- Create dimension table
CREATE TABLE airlines.airports_dim (
    airport_id BIGINT,
    city VARCHAR(100),
    state VARCHAR(100),
    name VARCHAR(200)
);

-- Load dimension data
COPY airlines.airports_dim
FROM 's3://airline-data-landing-zn/dim/airports.csv' 
IAM_ROLE 'arn:aws:iam::ACCOUNT:role/redshift-s3-role'
DELIMITER ',' IGNOREHEADER 1 REGION 'us-east-1';

-- Create fact table (populated by Glue)
CREATE TABLE airlines.daily_flights_fact (
    carrier VARCHAR(10),
    dep_airport VARCHAR(200),
    arr_airport VARCHAR(200),
    dep_city VARCHAR(100),
    arr_city VARCHAR(100),
    dep_state VARCHAR(100),
    arr_state VARCHAR(100),
    dep_delay BIGINT,
    arr_delay BIGINT
);
```

**3. Configure VPC & Security**
```bash
# Create S3 VPC endpoint (for Glue-Redshift communication)
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxxxx \
  --service-name com.amazonaws.us-east-1.s3 \
  --route-table-ids rtb-xxxxx

# Update Redshift security group (open port 5439)
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 5439 \
  --cidr 10.0.0.0/16
```

**4. Create Glue Connection (JDBC to Redshift)**
```bash
aws glue create-connection \
  --connection-input '{
    "Name": "redshift-connection",
    "ConnectionType": "JDBC",
    "ConnectionProperties": {
      "JDBC_CONNECTION_URL": "jdbc:redshift://cluster-endpoint:5439/dev",
      "USERNAME": "admin",
      "PASSWORD": "your-password"
    },
    "PhysicalConnectionRequirements": {
      "SubnetId": "subnet-xxxxx",
      "SecurityGroupIdList": ["sg-xxxxx"],
      "AvailabilityZone": "us-east-1a"
    }
  }'
```

**5. Create Glue Crawlers**
```bash
# Crawler 1: S3 daily flights data
aws glue create-crawler \
  --name flights-data-crawler \
  --role GlueServiceRole \
  --database airlines-table-catalog \
  --targets '{"S3Targets": [{"Path": "s3://airline-data-landing-zn/daily_flights/"}]}'

# Crawler 2: Redshift dimension table
aws glue create-crawler \
  --name airline_dim_crawler \
  --role GlueServiceRole \
  --database airlines-table-catalog \
  --targets '{"JdbcTargets": [{"ConnectionName": "redshift-connection", "Path": "dev/airlines/airports_dim"}]}'

# Crawler 3: Redshift fact table
aws glue create-crawler \
  --name airline_fact_crawler \
  --role GlueServiceRole \
  --database airlines-table-catalog \
  --targets '{"JdbcTargets": [{"ConnectionName": "redshift-connection", "Path": "dev/airlines/daily_flights_fact"}]}'
```

**6. Create Glue ETL Job**
```bash
# Upload PySpark script to S3
aws s3 cp aws_glue_etl_job.py s3://aws-glue-assets/scripts/

# Create Glue job
aws glue create-job \
  --name airline_data_ingestion \
  --role GlueServiceRole \
  --command '{
    "Name": "glueetl",
    "ScriptLocation": "s3://aws-glue-assets/scripts/aws_glue_etl_job.py",
    "PythonVersion": "3"
  }' \
  --default-arguments '{
    "--job-bookmark-option": "job-bookmark-enable",
    "--TempDir": "s3://aws-glue-assets/temporary/"
  }'
```

**7. Create SNS Topic**
```bash
aws sns create-topic --name airline-etl-notifications
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT:airline-etl-notifications \
  --protocol email \
  --notification-endpoint your-email@example.com
```

**8. Create Step Function**
```bash
# Create state machine from JSON definition
aws stepfunctions create-state-machine \
  --name airline-etl-orchestrator \
  --definition file://step_function_code.json \
  --role-arn arn:aws:iam::ACCOUNT:role/StepFunctionsExecutionRole
```

**9. Create EventBridge Rule**
```bash
aws events put-rule \
  --name airline-data-ingestion-trigger \
  --event-pattern file://event_bridge_rule.json

aws events put-targets \
  --rule airline-data-ingestion-trigger \
  --targets "Id"="1","Arn"="arn:aws:states:us-east-1:ACCOUNT:stateMachine:airline-etl-orchestrator"
```

## 📁 Project Structure

```
aws-glue-etl-airline-data-pipeline/
├── aws_glue_etl_job.py              # PySpark ETL transformation script
├── airports.csv                     # Airport dimension data (300+ records)
├── event_bridge_rule.json           # S3 event pattern for pipeline trigger
├── step_function_code.json          # State machine definition (workflow)
├── redshift_table_commands.txt      # DDL & COPY commands
├── docs/
│   ├── step-function-diagram.png    # Orchestration workflow visualization
│   └── glue-etl-job-diagram.png     # ETL data flow diagram
└── README.md
```

## 🔧 PySpark ETL Logic

### **Key Transformation Steps:**

**1. Filter Delayed Flights (> 60 minutes)**
```python
Filter.apply(
    frame=DailyFlightsData,
    f=lambda row: (row["depdelay"] > 60),
    transformation_ctx="Filter_node"
)
```

**2. Join with Departure Airport Dimension**
```python
Filter_DF.join(
    AirportDim_DF,
    Filter_DF["originairportid"] == AirportDim_DF["airport_id"],
    "left"
)
```

**3. Rename Departure Columns**
```python
ApplyMapping.apply(
    mappings=[
        ("city", "string", "dep_city", "string"),
        ("name", "string", "dep_airport", "string"),
        ("state", "string", "dep_state", "string")
    ]
)
```

**4. Join with Arrival Airport Dimension**
```python
DepartureEnriched_DF.join(
    AirportDim_DF,
    DepartureEnriched_DF["destairportid"] == AirportDim_DF["airport_id"],
    "left"
)
```

**5. Final Schema Transformation**
```python
ApplyMapping.apply(
    mappings=[
        ("carrier", "string", "carrier", "varchar"),
        ("depdelay", "long", "dep_delay", "bigint"),
        ("arrdelay", "long", "arr_delay", "bigint"),
        # ... departure and arrival airport details
    ]
)
```

**6. Load to Redshift**
```python
glueContext.write_dynamic_frame.from_options(
    frame=FinalData,
    connection_type="redshift",
    connection_options={
        "dbtable": "airlines.daily_flights_fact",
        "connectionName": "redshift-connection",
        "redshiftTmpDir": "s3://aws-glue-assets/temporary/"
    }
)
```

## 🌟 Key Technical Highlights

### **Event-Driven Architecture**
- ✅ **Fully automated** - No manual intervention required
- ✅ **Real-time triggers** - EventBridge captures S3 uploads instantly
- ✅ **Scalable** - Handles variable daily data volumes

### **Orchestration Excellence**
- ✅ **State management** - Step Functions with choice states & loops
- ✅ **Error handling** - SNS notifications on failures
- ✅ **Sync execution** - `.sync` pattern for Glue job completion

### **ETL Optimization**
- ✅ **Denormalized model** - Pre-joined fact table eliminates runtime joins
- ✅ **Partition pruning** - Hive-style partitions for efficient reads
- ✅ **PySpark transformations** - Distributed processing at scale

### **Monitoring & Observability**
- ✅ **SNS alerts** - Success/failure notifications
- ✅ **CloudWatch logs** - Glue job execution logs
- ✅ **Step Functions history** - Complete audit trail

## 🎯 Real-world Use Cases

- **📊 Operations Analytics** - Identify delay patterns for route optimization
- **💼 Business Intelligence** - Carrier performance dashboards
- **📈 Predictive Maintenance** - Correlate delays with weather/airport conditions
- **🏢 Executive Reporting** - KPIs on on-time performance
- **🔍 Root Cause Analysis** - Investigate chronic delay routes

## 🚀 Future Enhancements

- [ ] **📊 QuickSight Dashboards** - Real-time delay visualization
- [ ] **🤖 ML Integration** - Delay prediction models with SageMaker
- [ ] **⚡ Glue Streaming** - Real-time processing with Kinesis
- [ ] **🗂️ Data Partitioning** - Optimize Redshift with SORTKEY/DISTKEY
- [ ] **📧 Advanced Alerting** - Anomaly detection with CloudWatch
- [ ] **🔄 Incremental Processing** - Job bookmarks for delta loads

## 🤝 Contributing

Contributions welcome! Focus areas:
- **📊 Additional Analytics** - New delay analysis queries
- **🔧 Performance Tuning** - Redshift optimization strategies
- **🧪 Testing** - Unit tests for PySpark transformations
- **📈 Visualization** - QuickSight dashboard templates

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

**Automated airline analytics with serverless AWS architecture** ✈️☁️
