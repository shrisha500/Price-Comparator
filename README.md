# TaskFlow — AI-Enhanced Todo App with Meal Planning

**Name:** Qing Shen  
**UMID:** 85698478

---

## 📌 Project Overview

TaskFlow is a multi-user todo application built with **JacLang** that integrates **LLM-powered intelligence** to enhance task management. In addition to standard todo functionality (add, list, toggle, delete), the app introduces an AI-based feature that automatically categorizes todos and generates meal-planning shopping lists.

---

## ✨ Custom Feature Added

### AI-Powered Todo Categorization & Meal Planning

The custom feature uses a Large Language Model (LLM) to:

1. **Automatically categorize todos**  
   Each todo title is classified into one of the following categories:
   - WORK
   - PERSONAL
   - SHOPPING
   - HEALTH
   - OTHER
  The custom feature I added is AI-generated priority classification. For each task that a user adds, the AI automatically assigns a priority tag: "High", "Medium", or     "Low".
2. **Generate a meal shopping list from a meal description**  
   Users can describe a meal in natural language, and the app generates:
   - A list of ingredients
   - Quantities and units
   - Estimated costs
   - Whether each ingredient is high in carbohydrates

---

## 🛠️ Installation & Setup

### Prerequisites
- Python 3.10+
- JacLang
- An OpenAI API key with billing enabled

### 1️⃣ Clone the repository
```bash
git clone https://github.com/<your-username>/taskflow.git
cd taskflow
