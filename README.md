# YARALMA

**The Senegalese Value-Based Digital Shield**

YARALMA encodes the six pillars of Senegalese ancestral values—**Teranga**, **Jom**, **Kersa**, **Sutura**, **Muñ**, **Ngor**—into the digital tools families use every day. It gives parents a cultural sovereignty layer over global platforms like YouTube and Netflix, while respecting faith, language, and local norms.

---

## Vision & Goals

- **Cultural sovereignty** — A values-aware layer on top of global platforms (YouTube, Netflix), tuned to Senegalese taboos and religious rhythms.
- **Less conflict** — Automated, value-based scheduling to reduce parent–child friction around screen time.
- **Linguistic safety** — Filtering of harmful or disrespectful content in **Wolof** and local **French**.
- **Spiritual discipline** — Automatic sync with prayer times and Sunday Mass so devices support faith, not distract from it.

---

## The Problem

Senegalese parents face a **Digital Value Gap**:

- **Western-centric tools** — Existing parental controls don’t understand Senegalese taboos or religious schedules.
- **The algorithm trap** — YouTube and Netflix often recommend content that clashes with **Kersa** (modesty) or **Jom** (dignity).
- **Linguistic blindness** — Global systems ignore Wolof-language profanity and disrespect toward elders and religious figures.

YARALMA is built to close that gap.

---

## Who It’s For

| Audience | Context | Need |
|----------|---------|------|
| **Parents** (e.g. Demba, Joseph) | Muslim (Mouride/Tijaniyya) or Christian (Catholic), across Senegal | Protect children (3–12) from content that undermines religious education and local integrity (**Ngor**) |
| **Children** (3–12) | Heavy use of YouTube (cartoons, football, Senegalese series) and Netflix | Safer, value-aligned experience without feeling surveilled (**Sutura**) |

---

## MVP Features

### In scope (V1)

- **Android Accessibility Overlay** — Real-time visual blurring and audio muting on top of YouTube and Netflix.
- **Account linking** — OAuth for YouTube and Google Family Link.
- **Spiritual sync** — Location-based locks for Islamic prayer times and Sunday Mass.
- **WhatsApp dashboard** — Weekly reports (“Jom Report”) and remote commands (e.g. LOCK, +30 min).
- **Multi-language UI** — Setup and alerts in **French**, **Wolof**, and **Diola**.

### Out of scope (V1)

- Social media (TikTok, Instagram, Snapchat).
- Browser-wide filtering (only official YouTube/Netflix apps).
- Hardware (routers, modified devices).
- Granular surveillance (no private messages or detailed video history; **Sutura** first).

---

## Core Capabilities

| Area | What YARALMA does |
|------|-------------------|
| **Onboarding** | Value Agreement (6 pillars), Faith Shield (Mouride, Tijaniyya, General Muslim, Christian), guided Android Accessibility setup. |
| **YouTube Guardian** | Shorts shelf removal, search interception for blocked Wolof/French keywords, Explore Mode (9–12) or YouTube Kids (3–8). |
| **Netflix Overlay** | Real-time blur from community timestamps (“Lion Guardian”), hiding thumbnails that violate Kersa. |
| **Holy Lock** | Full-screen lock during 5 daily prayers (GPS-based), Sunday 08:00–11:30 for Christian profiles, Ramadan & Lent mode. |
| **WhatsApp** | Sunday summary report, remote lock/unlock via bot. |

---

## Tech Stack

| Layer | Choice |
|-------|--------|
| **Parent app** | Flutter |
| **Overlay / background** | Android Accessibility Service (Kotlin/Java) |
| **Backend** | Firebase (config sync, user profiles) |
| **Messaging** | Twilio WhatsApp Business API |
| **ASR** | Specialized Wolof acoustic model for real-time keyword detection |

---

## UX Principles

- **The Silent Lion** — Protection is discreet; blurs over alarms.
- **Sutura first** — Protect the child’s dignity; no shaming in front of parents.
- **Teranga design** — Warm, premium interface that feels like a gift to the family, not a digital prison.

---

## Success Metrics (KPIs)

- **Conversion** — % completing Account Link in under 5 minutes.
- **Filter accuracy** — % of inappropriate Wolof dialogue correctly muted.
- **Behavioral impact** — % of families reporting fewer screen-time arguments after using Lock.
- **Retention** — % renewing Faith Shield during Ramadan/Lent.

---

## Roadmap

| Version | Focus |
|---------|--------|
| **V1 (MVP)** | YouTube + Netflix overlay, Holy Lock, WhatsApp, multi-language UI. |
| **V2** | TikTok and Reels. |
| **V3** | Zero-rated data partnership (e.g. Orange/Free Senegal). |
| **V4** | Privacy-first, fully offline AI model. |

---

## Project Docs

- **[PRD](prd.md)** — Product requirements, functional specs, and scope.
- **[User journey](userjourney.md)** — End-to-end flows and personas.
- **[Master build guide](masterbuildguide.md)** — Implementation and setup.

---

## Status

**Draft / MVP definition.** This repository holds product and design documentation; implementation will follow the PRD and build guide.

---

*YARALMA — built with Teranga, for Senegalese families.*
