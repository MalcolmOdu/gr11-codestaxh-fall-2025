# </> CODESTAXH


Table of Contents:
1. Description
2. What makes CodeStaxh different
3. Features
4. Tech stack
5. Installation guide
6. How to use CodeStaxh
   
Description

Codestaxh is a cross platform code snippet library designed for developers who need quick
access to reusable code patterns. The app solves the "I know I wrote this before, but where?"
problem by providing a centralized, searchable library of code snippets accessible from both
web and mobile devices.
Web Version: Optimized for creating and editing snippets.
Mobile Version: Designed for quick reference: browse, search, view, and copy snippets on the go
with offline access.
The app enables team collaboration, allowing developers to share snippets in real time, upvote
the best solutions, and build an organized knowledge base specific to their projects and
workflows.

What makes it different?
+ actually works offline
+ syncs in real-time
+ team collaboration built-in
+ AI that's not mid
+ browser extension for Stack Overflow and Github
+ UI that goes hard
+ cross-platform (web + mobile) basically: you write code once, access it everywhere. no
more "wait where did i save that regex" moments.

Features 
 
Syntax Highlighting
15+ languages with proper highlighting. your code looks as good as it runs.
Smart Search
Find anything by title, tags, language, or even code content.
Real-time Sync
Edit on web, update yourself and your team immediately.
Team Collab
Share snippets with your team. no more dm'ing code through slack.
AI-Powered
Automatically tag your snippets or get quick and concise descriptions of snippets.
Browser Extension
Save snippets directly from Stack Overflow. One click and you're done.

Tech Stack 

Frontend
• Firebase Auth - Google/GitHub/Email sign-in
• Flutter – smooth and UX operable on nearly all devices/
• Material 3 – Three-dimensional appearance
• Custom Animations – enhance user experience during loading wait times.

Backend
• Firebase Auth - Google/GitHub/Email sign-in
• Firestore - real-time sync
• Hive - offline storage
• Riverpod - state management
• Gemini API – ai features (descriptions, auto-tagging)

Platforms
• Web (deployed on Firebase Hosting)
• Mobile (Android)
• Chrome Extension

Installation
Web: just go to gr11-codestaxh-fall-2025.web.app ← it's literally that easy
Mobile: simply install CodeStaxh.apk in this repository’s root directory.
How to use
1. Sign in - google, github, or email.
2. Create snippet (webapp) - paste code, add tags, done.
3. Search – Find snippets from yourself, others, or your team.
4. Share - create a team, invite people, share snippets.

architecture

lib/

├── models/ # data models

├── controllers/ # business logic

├── views/ # UI screens

│ ├── web/ # web-specific views

│ ├── mobile/ # mobile-specific views

│ └── shared/ # shared views

├── widgets/ # reusable components

└── theme/
