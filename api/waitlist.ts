import type { VercelRequest, VercelResponse } from '@vercel/node';

const NOTION_API = 'https://api.notion.com/v1/pages';
const DATABASE_ID = '2fe272b56797808da469f8a8b3fc059a';
const NOTION_API_KEY = process.env.NOTION_API_KEY;
const RESEND_API_KEY = process.env.RESEND_API_KEY;

const SETUP_GUIDE = `
# OpenClaw Setup Guide

Welcome! Here's how to get OpenClaw running:

## 1. Prerequisites
- Node.js 18+ installed
- OpenAI API key (or Anthropic/other LLM provider)
- Mac, Linux, or WSL on Windows

## 2. Install OpenClaw
\`\`\`bash
git clone https://github.com/steipete/OpenClaw.git
cd OpenClaw
npm install
\`\`\`

## 3. Configure
Copy the example config and add your API keys:
\`\`\`bash
cp .env.example .env
# Edit .env with your API keys
\`\`\`

## 4. Run
\`\`\`bash
npm start
\`\`\`

## 5. Connect Your Apps
OpenClaw works with:
- Gmail (for email automation)
- Google Calendar (for scheduling)
- Notion (for knowledge base)
- WhatsApp & Telegram (for messaging)

Follow the prompts to connect each service.

## Need Help?
Reply to this email if you get stuck. We're here to help!
`;

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { email } = req.body;

  if (!email || !email.includes('@')) {
    return res.status(400).json({ error: 'Invalid email' });
  }

  try {
    // 1. Save to Notion
    if (NOTION_API_KEY) {
      await fetch(NOTION_API, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${NOTION_API_KEY}`,
          'Content-Type': 'application/json',
          'Notion-Version': '2022-06-28',
        },
        body: JSON.stringify({
          parent: { database_id: DATABASE_ID },
          properties: {
            Email: {
              title: [{ text: { content: email } }],
            },
            'Signed Up': {
              date: { start: new Date().toISOString() },
            },
          },
        }),
      });
    }

    // 2. Send email via Resend
    if (RESEND_API_KEY) {
      await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${RESEND_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: 'OpenClaw <noreply@weblydev.com>',
          to: email,
          subject: 'Your OpenClaw Setup Guide',
          html: SETUP_GUIDE.replace(/\n/g, '<br>').replace(/```/g, '').replace(/`/g, ''),
        }),
      });
    }

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: 'Failed to process request' });
  }
}
