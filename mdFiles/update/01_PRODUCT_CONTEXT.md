# Collector App — Product Context

## What this app is
Collector App is a mobile app for tracking and enjoying a personal collection of collectibles such as:
- action figures
- memorabilia
- statues
- comics
- trading cards
- similar collector items

## Product thesis
Most competitor apps feel outdated or behave like inventory databases.
This product should feel like a **beautiful digital home for collectors**.

## Core promise
Organize, visualize, and enjoy your collection in a modern way.

## Desired product qualities
- visual-first
- mobile-first
- premium but simple
- low-friction
- collector identity, not spreadsheet energy

## MVP goals
The first version should let a user:
1. Add collectibles easily
2. Browse their collection in a visual way
3. View and edit item details
4. Track wishlist items
5. Mark favorites, grails, duplicates, and trade intent
6. Upload at least one main photo per item

## Initial product scope
### In
- authentication
- collection list
- add collectible
- collectible detail
- edit/delete collectible
- one main photo per item
- wishlist
- favorites
- grails
- duplicates
- open to trade flag
- search and basic filters
- basic dashboard stats
- profile basics

### Out for now
- marketplace
- social feed
- chat
- advanced price tracking
- AI identification as a hard dependency
- desktop-specific experiences

## Category strategy for MVP
The app should be **multi-category**, but with strong DNA around toys / action figures.

### Default categories
Use these curated default categories:
- Action Figures
- Statues
- Vinyl Figures
- Trading Cards
- Comics
- Memorabilia
- Die-cast
- Other

### Custom category behavior
The user should also be able to create a custom category if none of the defaults fit.

Important rules:
- Do not store **"New Category"** as an actual category value
- In the UI, use a pattern like **"Create custom category"**
- Store the actual custom text the user enters
- For MVP, `category` can remain a text field in the database
- Default categories are mainly a UX convenience, not a hard backend limitation

### Why this approach
This keeps the experience flexible without overengineering the schema too early.
