# OCV — OpenClaw Version Control

> 在飞书里说"保存一下"，AI Agent 就帮你把整个 ~/.openclaw/ 备份到 git。

## 一句话说明

OCV 是 OpenClaw 的备份插件，让用户通过自然语言管理 Agent 的完整备份与恢复。

## 功能

| 命令 | 功能 |
|------|------|
| `ocv save [msg]` | 保存当前状态 (提交 + 推送) |
| `ocv restore <url>` | 从 git 仓库恢复 |
| `ocv status` | 查看变更状态 |
| `ocv log [n]` | 查看最近 n 条保存记录 |
| `ocv rollback <hash>` | 回滚到指定版本 |
| `ocv auto on/off/status` | 自动保存开关 |
| `ocv init` | 初始化备份仓库 |

## 快速开始

### 方式一：通过聊天（推荐）

```
用户: 保存一下
Agent: 💾 已保存! a3f8b21 — 3 个文件变更 → 已推送

用户: 回滚到上一个版本
Agent: ⏪ 已回滚到 b7c2e45
```

### 方式二：直接用 CLI

```bash
# 1. 初始化 (首次)
ocv init --remote git@github.com:you/my-openclaw.git

# 2. 保存
ocv save "优化了SEO策略"

# 3. 查看状态
ocv status

# 4. 查看历史
ocv log

# 5. 回滚
ocv rollback abc1234 --yes

# 6. 开启自动保存
ocv auto on
```

## 备份范围

**全部备份** (`~/.openclaw/`)：
- openclaw.json — 全局配置
- credentials/ — API Keys
- workspace/ — 核心工作区 (skills, memory, AGENTS.md, SOUL.md 等)
- extensions.lock.json — Extension 版本清单
- skills/ — managed skills
- memory/ — 记忆数据

**不备份** (.gitignore)：
- extensions/ — Extension 源码（通过 lock 文件记录，恢复时自动安装）
- sessions/ — 运行时会话
- sandboxes/ — 沙箱
- .cache/ — 缓存
- *.log — 日志文件
- node_modules/ — npm 依赖

## 安全提醒

⚠️ **credentials 会被备份到 git。务必使用私有仓库！**

## 安装

```bash
# 作为 OpenClaw skill 使用
# 无需单独安装，Agent 会自动加载 ocv skill

# 或独立安装 CLI
npm i -g ocv
```

## Auto Save

```bash
# 开启自动保存 (每30分钟检查一次，有变化自动保存)
ocv auto on

# 查看自动保存状态
ocv auto status

# 关闭
ocv auto off
```

## 在新机器恢复

```bash
ocv restore git@github.com:you/my-openclaw.git
```

---

🦐 *Your agent evolves. Your backup should too.*
