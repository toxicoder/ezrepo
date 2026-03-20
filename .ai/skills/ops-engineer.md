# Skill: Operations Engineer

> **Version**: 2.0
> **Last Updated**: 2026-03-19
> **Purpose**: Establish a production-grade framework for managing, monitoring, and troubleshooting containerized development and runtime environments

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [Workflow Pipeline](#workflow-pipeline)
3. [Tool Selection Matrix](#tool-selection-matrix)
4. [Environment Management](#environment-management)
5. [Container Orchestration](#container-orchestration)
6. [System Health Monitoring](#system-health-monitoring)
7. [Troubleshooting Procedures](#troubleshooting-procedures)
8. [Security & Compliance](#security--compliance)
9. [Error Handling & Fallbacks](#error-handling--fallbacks)
10. [Verification & Validation](#verification--validation)
11. [Best Practices Checklist](#best-practices-checklist)

---

## Core Principles

| Principle                 | Description                                                           | Anti-Pattern to Avoid                                            |
| :------------------------ | :------------------------------------------------------------------- | :-------------------------------------------------------------- |
| **Environment Reproducibility** | All environments should be reproducible from configuration      | Hardcoded configurations that work only on specific machines   |
| **Immutable Infrastructure**    | Containers are treated as immutable; changes via rebuild    | Making manual changes inside running containers                |
| **Health-First Monitoring**     | System health is continuously monitored and alerting         | Discovering issues only after user reports                     |
| **Docker-in-Docker Safety**     | DinD operations follow strict safety protocols               | Running destructive Docker commands without verification       |
| **Zero Downtime Deployments**   | Deployments scheduled to minimize service disruption         | Downtime during maintenance windows                            |
| **Audit Trail**                 | All environment changes are logged for traceability          | Making environment changes without logging                     |

---

## Workflow Pipeline

### Phase 1: Environment Inspection

**Objective**: Understand current state of the containerized environment

#### Actions

1. **System health check**
   - Verify Docker daemon status
   - Check container runtime version
   - Confirm resource availability (CPU, memory, disk)

2. **Devcontainer inspection**
   - Use `devcontainer` MCP to read configuration
   - Identify attached volumes and ports
   - Review installed tools and extensions

3. **Network verification**
   - Check network connectivity
   - Verify DNS resolution
   - Test external service access

#### Output

- Current environment assessment report
- Health status summary
- Configuration inventory

### Phase 2: Service Management

**Objective**: Start, stop, or configure services as needed

#### Actions

1. **Docker-in-Docker operations**
   - Launch containers using proper networking
   - Configure appropriate resource limits
   - Set up volume mounts for persistence

2. **Service orchestration**
   - Start required services (databases, caches, queues)
   - Configure service dependencies
   - Verify inter-service connectivity

3. **Cleanup procedures**
   - Remove stopped containers
   - Prune unused images
   - Clean up orphaned volumes

#### Output

- Services running with proper configuration
- Resource usage within limits
- Clean repository state

### Phase 3: Testing Support

**Objective**: Provide infrastructure for testing scenarios

#### Actions

1. **Test environment setup**
   - Spin up test databases
   - Configure test services
   - Set up test data fixtures

2. **Integration testing**
   - Verify service connectivity
   - Run integration test suites
   - Capture test results

3. **Teardown procedures**
   - Stop test services
   - Clean up test data
   - Restore original state

#### Output

- Test environment ready for use
- Test results captured
- Clean teardown completed

### Phase 4: Troubleshooting

**Objective**: Diagnose and resolve environment issues

#### Actions

1. **Issue identification**
   - Review error logs
   - Check system metrics
   - Identify failure patterns

2. **Root cause analysis**
   - Examine container logs
   - Review resource utilization
   - Check configuration drift

3. **Resolution execution**
   - Apply fixes
   - Restart affected services
   - Verify resolution

#### Output

- Issue resolved or escalated
- Root cause documented
- Preventive measures identified

### Phase 5: Monitoring & Alerting

**Objective**: Maintain continuous visibility into system health

#### Actions

1. **Metrics collection**
   - CPU and memory usage
   - Disk utilization
   - Network I/O

2. **Log aggregation**
   - Container logs
   - Application logs
   - System logs

3. **Alert configuration**
   - Set up threshold alerts
   - Configure escalation policies
   - Document on-call procedures

#### Output

- Metrics dashboard
- Log aggregation configured
- Alert rules active

---

## Tool Selection Matrix

| Task                              | Primary Tool       | Fallback                   | When to Use                                      | Notes                                       |
| :-------------------------------- | :----------------- | :------------------        | :---------------------------------------------- | :--------------------------------------       |
| List containers                   | `execute_command`  | `docker` CLI               | Check running/stopped containers                 | `docker ps -a`                              |
| View container logs               | `execute_command`  | `docker logs`              | Debug container issues                           | `docker logs <container> --tail 100`       |
| Inspect container details         | `execute_command`  | `docker inspect`           | Get detailed container configuration             | `docker inspect <container>`                |
| Execute in container              | `execute_command`  | `docker exec`              | Run commands inside running container            | `docker exec -it <container> bash`          |
| Start container                   | `execute_command`  | `docker run`               | Launch new container                             | Use proper networking and volume mounts     |
| Stop container                    | `execute_command`  | `docker stop`              | Gracefully stop container                        | Allow graceful shutdown                     |
| Remove container                  | `execute_command`  | `docker rm`                | Clean up stopped containers                      | Use `-f` only when necessary                |
| List images                       | `execute_command`  | `docker images`            | View available images                            | `docker images -a`                          |
| Remove image                      | `execute_command`  | `docker rmi`               | Clean up unused images                           | Use with caution                            |
| System prune                      | `execute_command`  | `docker system prune`      | Clean up unused resources                        | Requires approval for safety                |
| Devcontainer info                 | `devcontainer` MCP | `devcontainer` CLI         | Read devcontainer configuration                  | MCP server provides structured data         |
| Version verification              | `execute_command`  | Direct command             | Check tool versions                              | `node --version`, `python --version`, etc. |
| Network inspection                | `execute_command`  | `docker network inspect`   | Check container networking                       | `docker network ls`                         |
| Volume inspection                 | `execute_command`  | `docker volume ls`         | Check storage volumes                            | `docker volume ls -f dangling=true`         |

---

## Environment Management

### Devcontainer Configuration

The devcontainer configuration should include:

```json
{
  "name": "Development Container",
  "image": "mcr.microsoft.com/devcontainers/ubuntu:0-24.04",
  "features": {
    "ghcr.io/devcontainers/features/node:1": {},
    "ghcr.io/devcontainers/features/python:1": {}
  },
  "runArgs": [
    "--network=host"
  ],
  "mounts": [
    "type=volume,source=devdata,target=/home/node/data"
  ],
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode-remote.remote-containers",
        "dbaeumer.vscode-eslint"
      ]
    }
  }
}
```

### Container Networking

| Network Mode    | When to Use                                    | Example Use Case                    |
| :-------------- | :--------------                                | :----------                         |
| **host**        | External access required                       | Local development, debugging       |
| **bridge**      | Default; container isolation                   | Standard application containers    |
| **none**        | Isolated containers                            | Security-sensitive workloads       |
| **custom**      | Specific network requirements                  | Multi-container applications       |

### Resource Limits

Always set resource limits for containers:

```json
{
  "HostConfig": {
    "Memory": "512m",
    "MemorySwap": "1g",
    "CpuShares": 512,
    "BlkioWeight": 500
  }
}
```

---

## Container Orchestration

### Docker Compose Usage

Simple services can be managed with docker-compose:

```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
    depends_on:
      - db
  
  db:
    image: postgres:15
    environment:
      - POSTGRES_PASSWORD=secret
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

### Sidecar Pattern

For testing scenarios, use sidecar containers:

```zsh
# Start database as sidecar for testing
docker run -d \
  --name test-db \
  -e POSTGRES_PASSWORD=test \
  -p 5432:5432 \
  postgres:15

# Run tests
npm test

# Cleanup
docker stop test-db && docker rm test-db
```

---

## System Health Monitoring

### Health Check Commands

```zsh
# Docker daemon status
docker info > /dev/null && echo "Docker: OK" || echo "Docker: FAILED"

# Container status
docker ps --format "{{.Names}}\t{{.Status}}"

# System resources
df -h
free -h
```

### Health Metrics to Monitor

| Metric          | Healthy Range         | Alert Threshold      | Action Required                       |
| :-------------  | :-------------         | :-------------       | :-------------                        |
| **CPU Usage**   | <70% sustained        | >90% for 5 min       | Investigate process, consider scaling |
| **Memory**      | <80% available         | <10% available       | Investigate memory leak               |
| **Disk Space**  | >20% free              | <10% free            | Clean up images/volumes               |
| **Network**     | <100ms latency         | >1000ms latency      | Check network connectivity            |
| **Containers**  | Expected count         | Count mismatch       | Investigate failed containers         |

### Log Monitoring

```zsh
# Monitor container logs in real-time
docker logs -f <container>

# Search logs for errors
docker logs <container> | grep -i error

# Check container restart count
docker ps -a --format "{{.Names}}\t{{.Status}}"
```

---

## Troubleshooting Procedures

### Common Error Scenarios

| Error Scenario            | Immediate Action                                   | Escalation Path                                                  |
| :------------------------ | :------------------------------------------------- | :--------------------------------------------------------------- |
| **Container won't start** | Check logs, verify image exists, check port conflicts | Verify image build, check Docker daemon                      |
| **Network unreachable**   | Verify network mode, check firewall rules          | Test network connectivity, check Docker daemon config         |
| **Permission denied**     | Check user group membership, volume permissions    | Run with sudo, adjust permissions, check SELinux/AppArmor    |
| **Resource exhausted**    | Free up resources, increase limits                 | Scale up resources, optimize container configuration          |
| **Docker daemon fails**   | Check systemd status, review daemon logs           | Restart Docker, check for port conflicts, verify config      |
| **DinD networking issues**| Verify Docker-in-Docker network configuration     | Use --network=host or custom bridge network                  |

### Log Analysis

```zsh
# Container logs
docker logs <container> 2>&1 | tee /tmp/container.log

# Docker daemon logs
sudo journalctl -u docker.service -n 100

# System logs
dmesg | tail -50

# Resource usage
docker stats --no-stream
```

### Debugging Checklist

- [ ] Verify Docker daemon is running
- [ ] Check container logs for errors
- [ ] Verify network connectivity
- [ ] Check resource limits
- [ ] Review volume mounts
- [ ] Confirm image exists and is accessible
- [ ] Test with minimal configuration

---

## Security & Compliance

### Container Security

| Security Control          | Implementation                                  | Verification Method                    |
| :------------------       | :--------------------------------              | :-----------                           |
| **Non-root containers**   | Run as non-root user                            | `USER` directive in Dockerfile          |
| **Minimal images**        | Use Alpine or distroless base images            | Image size check                        |
| **Secret management**     | Use Docker secrets or environment variables     | Audit secret handling                   |
| **Image scanning**        | Scan images for vulnerabilities                 | `docker scan` or third-party tools     |
| **Network isolation**     | Use custom networks, restrict ports             | `docker network inspect`                |

### Docker Security Best Practices

```dockerfile
# ✓ Secure Dockerfile
FROM node:20-alpine

# Non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY --chown=nodejs:nodejs . .

USER nodejs

EXPOSE 3000

CMD ["node", "server.js"]
```

### Compliance Checklist

- [ ] No secrets in Docker images
- [ ] Images scanned for vulnerabilities
- [ ] Containers run as non-root
- [ ] Network isolation configured
- [ ] Resource limits set
- [ ] Logs are captured and retained
- [ ] Audit logging enabled

---

## Error Handling & Fallbacks

### Common Error Scenarios

| Error Scenario            | Immediate Action                                   | Escalation Path                                                  |
| :------------------------ | :------------------------------------------------- | :--------------------------------------------------------------- |
| **Container failure**     | Check logs, restart container, verify config       | Rebuild image, check for resource issues                      |
| **Docker daemon down**    | Restart daemon, check for conflicting processes    | System reboot if daemon fails to restart                      |
| **Image pull failure**    | Check registry, verify credentials, retry          | Use cached image, check network connectivity                  |
| **Volume mount failure**  | Verify path exists, check permissions              | Create path, adjust permissions, check SELinux               |
| **Port conflict**         | Change host port, check for existing processes     | Kill conflicting process, use dynamic port allocation        |
| **Network isolation**     | Verify network configuration, check firewall       | Use host networking, debug with `docker network inspect`     |

### Retry Strategy

```zsh
# Pattern: Retry Docker operations with exponential backoff
attempt=1
max_attempts=3
sleep_time=2

while [ $attempt -le $max_attempts ]; do
  if docker ps > /dev/null 2>&1; then
    echo "Docker accessible"
    break
  fi
  echo "Attempt $attempt failed, retrying in $sleep_time seconds..."
  sleep $sleep_time
  sleep_time=$((sleep_time * 2))
  attempt=$((attempt + 1))
done
```

### Logging Requirements

Every operations action should log:

```markdown
## Operations Log

- **Timestamp**: YYYY-MM-DD HH:MM:SS
- **Action**: [container_start|container_stop|service_create|cleanup]
- **Target**: [container/service name]
- **Status**: [success|failed]
- **Duration**: [seconds]
- **Error**: [if applicable]
- **Resource Usage**: [CPU, memory at end]
```

---

## Verification & Validation

### Automated Checks

Run these after each major operation:

#### Container Start Checklist

- [ ] Container status is "Up"
- [ ] Expected ports are mapped
- [ ] Health checks pass (if configured)
- [ ] Logs show no errors
- [ ] Network connectivity verified

#### Container Stop Checklist

- [ ] Container status is "Exited" or "Created"
- [ ] No lingering processes
- [ ] Cleanup completed (if automatic)

#### Resource Cleanup Checklist

- [ ] Stopped containers removed
- [ ] Unused images pruned
- [ ] Orphaned volumes cleaned
- [ ] Disk space verified (>10% free)

### Manual Verification

When uncertainty exists:

1. **Log review**: Do logs show expected behavior?
2. **Test connectivity**: Can services communicate?
3. **Verify resource usage**: Are resources within limits?
4. **Check health**: Are all services healthy?

### Success Criteria

Operations are successful when:

- All containers running with expected configuration
- Resource usage within acceptable limits
- No security vulnerabilities in images
- All health checks passing
- Logs captured and accessible

---

## Best Practices Checklist

### Pre-Container Checklist

- [ ] Verify Docker daemon is running
- [ ] Check for port conflicts
- [ ] Verify image exists locally or in registry
- [ ] Plan resource limits
- [ ] Define logging configuration

### During Container Operation Checklist

- [ ] Monitor resource usage
- [ ] Check logs periodically
- [ ] Verify health check status
- [ ] Review network connectivity
- [ ] Check for security updates

### Post-Operation Checklist

- [ ] Verify container status
- [ ] Check resource cleanup
- [ ] Review logs for errors
- [ ] Update documentation if needed
- [ ] Clean up test data

### Emergency Stop Checklist

If encountering unexpected issues:

- [ ] **Check Docker status**: Is daemon running?
- [ ] **Review logs**: What errors are present?
- [ ] **Check resources**: Are limits being exceeded?
- [ ] **Verify configuration**: Is config valid?
- [ ] **Report**: Document exactly what failed and when

---

## Quick Reference

### Common Docker Commands

```zsh
# List all containers (running and stopped)
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# View recent logs from a container
docker logs <container> --tail 100 -f

# Execute command in running container
docker exec -it <container> /bin/bash

# Inspect container details
docker inspect <container> --format '{{.Config.Image}}'

# Remove stopped containers
docker container prune -f

# Remove unused images
docker image prune -a -f

# System-wide cleanup
docker system prune -a -f --volumes

# Check disk usage
docker system df
```

### Version Check Commands

```zsh
# Node.js version
node --version  # Expected: v20.x or v18.x (LTS)

# Python version
python --version  # Expected: Python 3.12.x

# Docker version
docker --version  # Expected: Docker version 24.x or higher

# Docker Compose version
docker-compose --version
```

### Network Debugging

```zsh
# List networks
docker network ls

# Inspect network
docker network inspect <network>

# Test connectivity
docker exec <container> ping <target>

# DNS resolution test
docker exec <container> nslookup <hostname>
```

---

## Revision History

| Version | Date       | Changes                                                                 |
| :------ | :--------- | :---------------------------------------------------------------------- |
| 1.0     | Initial    | Minimal 3-point workflow outline                                       |
| 2.0     | 2026-03-19 | Complete rewrite: added principles, workflow pipeline, tool matrix, environment management, container orchestration, system health monitoring, troubleshooting procedures, security & compliance, error handling, verification, and best practices |

---

**End of Operations Engineer Skill**