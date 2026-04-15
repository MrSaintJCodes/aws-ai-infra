# 🧠 AI Chat Application (Django + Ollama + AWS)

A production-ready AI chat application built with **Django**, powered by **Ollama (LLMs)**, and deployed on **AWS infrastructure using Terraform**.

This project demonstrates full-stack development combined with cloud infrastructure, automation, and scalable architecture.

<img width="978" height="1374" alt="Image" src="https://github.com/user-attachments/assets/2c94c0aa-ba4b-4095-a8ed-cf7940233aef" />

---

## 🚀 Features

* 💬 Chat interface with conversation history
* 🤖 AI responses powered by local LLMs (Ollama)
* ⚡ Async frontend (no page reloads)
* 🧠 Context-aware conversations (stored in DB)
* 🗂 Session-based chat tracking
* 🔄 Persistent storage using PostgreSQL (RDS) or SQLite fallback
* 📦 Static asset handling via Django + Apache
* 🌐 Deployed behind AWS Application Load Balancer (ALB)

---

## 🏗 Architecture

```
User → ALB → EC2 (Apache + Django)
                    ↓
                 Ollama API (LLM)
                    ↓
                 Database (RDS PostgreSQL / SQLite)
```

### AWS Components

* VPC (3-tier architecture)
* Application Load Balancer (ALB)
* Auto Scaling Group (ASG)
* EC2 instances (Ubuntu)
* EFS (shared storage for models)
* RDS PostgreSQL
* IAM roles (least privilege)
* CloudWatch (logging/monitoring)

---

## 🛠 Tech Stack

### Backend

* Python 3
* Django
* SQLite / PostgreSQL
* Apache + mod_wsgi

### AI

* Ollama
* LLaMA models (e.g. `llama3.2`, `llama3.2:1b`)

### Frontend

* HTML / CSS
* Vanilla JavaScript (fetch API)

### DevOps / Infra

* Terraform
* AWS (EC2, ALB, EFS, RDS)
* Git

---

## 📦 Project Structure

```
ai_chat/
├── ai_chat/              # Django project
├── chat/                 # Chat app
├── static/               # CSS / JS
├── templates/            # HTML templates
├── manage.py
└── requirements.txt
```

---

## ⚙️ Setup (Local Development)

### 1. Clone repo

```
git clone https://github.com/yourusername/ai-chat.git
cd ai-chat
```

---

### 2. Create virtual environment

```
python3 -m venv venv
source venv/bin/activate
```

---

### 3. Install dependencies

```
pip install -r requirements.txt
```

---

### 4. Run migrations

```
python manage.py migrate
```

---

### 5. Start server

```
python manage.py runserver
```

---

## 🤖 Ollama Setup

Install Ollama:

```
curl -fsSL https://ollama.com/install.sh | sh
```

Run model:

```
ollama pull llama3.2:1b
ollama serve
```

---

## 🔐 Environment Variables

The app supports both PostgreSQL (prod) and SQLite (fallback).

### PostgreSQL (optional)

```
export DB_HOST=...
export DB_NAME=...
export DB_USER=...
export DB_PASS=...
export DB_PORT=5432
```

### Ollama

```
export OLLAMA_HOST=http://localhost:11434
export OLLAMA_MODEL=llama3.2:1b
```

---

## 🧠 Database Behavior

* If DB environment variables are set → uses PostgreSQL
* If not → falls back to SQLite (`db.sqlite3`)

---

## 🌐 Deployment Notes

* Served via **Apache + mod_wsgi**
* Static files handled with `collectstatic`
* Behind AWS ALB (public access point)
* Instances pull models from shared EFS

---

## ⚡ Performance Considerations

* LLM inference is the main latency factor
* Smaller models (`1b`, `3b`) improve response time
* GPU instances (`g4dn`, `g5`) significantly improve performance
* ALB and Apache timeouts increased to avoid 502 errors

---

## 🚧 Future Improvements

* 🔄 Streaming responses (real-time token output)
* ⚙️ Background workers (Celery + Redis)
* 🎨 Enhanced chat UI (typing indicators, avatars)
* 🧠 Model selection per request
* 📊 Monitoring dashboards

---

## 🐞 Known Issues

* Long responses may cause timeouts without proper configuration
* Ollama must be running and accessible from Django
* First request may be slower due to model loading

---

## 📸 Demo

*(Add screenshots or GIFs here)*

---

## 📄 License

MIT License

---

## 👤 Author

**Justin St-Laurent**
Cloud / DevOps / Infrastructure Enthusiast
Focused on automation, IaC, and scalable systems

---

## 💡 Inspiration

Built to combine:

* AI applications
* Cloud infrastructure
* Real-world DevOps practices

---

## ⭐ If you like this project

Give it a star and feel free to contribute!
