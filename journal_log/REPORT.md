# Educational Mobile Application (MVP)

## Project Variant Selection

As part of the coursework, three implementation variants were proposed.  
For this project, **the third variant was selected**.

---

## MVP Application Description

The developed application is a **mobile educational platform**, similar in concept to *EduPage*, designed to facilitate interaction between students and teachers.

### MVP Goal

The goal of the MVP (Minimum Viable Product) is to create a minimal working version of the application that demonstrates the core system architecture, client–server interaction, and basic functionality.

---

## Core MVP Features

The MVP includes the following functionality:

- User registration and authentication  
- Role-based access (student / teacher)  
- Viewing class schedules  
- Viewing a list of subjects  
- Accessing basic academic information  

---

## Application Architecture

The application follows a **client–server architecture** and consists of two main components.

### Backend

- Server-side application deployed using **Docker**
- Provides a **REST API** for the mobile application
- Handles request processing, user management, and database operations
- Containerization simplifies deployment and scalability

### Mobile Application

- Client-side application developed using **Flutter**
- Cross-platform support (Android, with potential iOS support)
- Communicates with the backend via **HTTP requests**
- Displays data received from the backend in a user-friendly interface

---

## MVP Limitations

The following features are **not included** in the MVP version:

- Grading system and homework management
- Push notifications
- Advanced profile settings
- Internal messaging or chat functionality

These features can be implemented in future versions of the application.

---
