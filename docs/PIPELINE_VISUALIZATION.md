```mermaid
graph TD
    A["📥 Git Push to main<br/>or Pull Request"] --> B["🔐 Security Scans<br/>Trufflehog, pip-audit, Snyk"]
    
    B --> C["🧪 Backend Tests<br/>pytest + coverage"]
    B --> D["🧪 Frontend Tests<br/>npm test + coverage"]
    
    C --> E["📊 Upload to Codecov"]
    D --> F["📊 Upload to Codecov"]
    
    C --> G["🏗️ Build Frontend<br/>npm build"]
    D --> G
    
    G --> H["🐳 Build Docker Images<br/>Backend + Frontend"]
    
    H --> I["🔍 Scan with Trivy<br/>Backend Image"]
    H --> J["🔍 Scan with Trivy<br/>Frontend Image"]
    
    I --> K["📋 Generate SARIF<br/>Reports"]
    J --> K
    
    K --> L["📤 Upload to GitHub<br/>Security Tab"]
    
    L --> M["📦 Push to Registries"]
    
    M --> N["🐳 DockerHub<br/>if configured"]
    M --> O["☁️ AWS ECR<br/>with OIDC"]
    
    O --> P["🚀 Manual Deploy<br/>to ECS<br/>deploy-ecs.yml"]
    
    style A fill:#e1f5ff
    style B fill:#fff3e0
    style C fill:#f3e5f5
    style D fill:#f3e5f5
    style G fill:#e8f5e9
    style H fill:#ffe0b2
    style I fill:#ffccbc
    style J fill:#ffccbc
    style K fill:#b2dfdb
    style L fill:#b2dfdb
    style M fill:#c8e6c9
    style N fill:#c8e6c9
    style O fill:#a5d6a7
    style P fill:#81c784
```

## Pipeline Status Indicators

| Stage | Status | Time | Retry |
|-------|--------|------|-------|
| Security | ⚠️ Non-blocking | ~2 min | Auto on failure |
| Testing | ❌ Blocks on failure | ~3 min | Manual retry |
| Build | ❌ Blocks on failure | ~4 min | Manual retry |
| Scan | ⚠️ Informational | ~3 min | Auto on failure |
| Push | ❌ Only if main branch | ~2 min | Manual retry |
| Deploy | 🟡 Manual trigger | ~5 min | Manual trigger |

---

## Job Dependencies

```
┌─────────────┐
│  security   │ (always runs)
└──────┬──────┘
       │
       ├──────────────────────┬──────────────────────┐
       ▼                      ▼                      ▼
   ┌────────────┐      ┌────────────┐      ┌──────────────┐
   │test-backend│      │test-frontend     │build-frontend│
   └─────┬──────┘      └────┬──────┘      └────┬─────────┘
         │                  │                   │
         └──────────────────┼───────────────────┘
                            ▼
                      ┌─────────────┐
                      │build-images │
                      └──────┬──────┘
                             ▼
                      ┌──────────────┐
                      │scan-images   │
                      └──────┬───────┘
                             ▼
                      ┌──────────────┐
                      │ push-ecr     │
                      │(if main)     │
                      └──────┬───────┘
                             ▼
                      ┌──────────────┐
                      │deploy-ecs    │
                      │(manual)      │
                      └──────────────┘
```

---

## Execution Timeline (Typical Run)

```
0:00s   → 🟢 Workflow starts
0:15s   → Security scans begin (parallel)
2:00s   → ✅ Security scans complete
2:05s   → Backend & Frontend tests start (parallel)
2:10s   → Frontend build starts
5:00s   → ✅ All tests & build complete
5:10s   → Docker images building
7:00s   → Images built, Trivy scanning starts
9:00s   → ✅ Container scan complete
9:05s   → Image upload to ECR starts
10:30s  → ✅ Images pushed to ECR
10:31s  → 🟡 Awaiting manual deployment trigger

Manual trigger:
0:00s   → Deploy job starts
0:30s   → Update task definition
1:00s   → Update ECS service
5:00s   → ✅ Service stable, deployment complete
```

