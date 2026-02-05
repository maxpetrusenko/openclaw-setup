import type { VercelRequest, VercelResponse } from '@vercel/node';

const NOTION_API = 'https://api.notion.com/v1/pages';
const DATABASE_ID = '2fe272b56797808da469f8a8b3fc059a';
const NOTION_API_KEY = process.env.NOTION_API_KEY;
const RESEND_API_KEY = process.env.RESEND_API_KEY;

const SETUP_GUIDE = `
<h1>OpenClaw Setup Guide</h1>

<p>Welcome! Here's how to get OpenClaw running:</p>

<h2>1. Prerequisites</h2>
<ul>
  <li>Node.js 18+ installed</li>
  <li>OpenAI API key (or Anthropic/other LLM provider)</li>
  <li>Mac, Linux, or WSL on Windows</li>
</ul>

<h2>2. Install OpenClaw</h2>
<pre><code>git clone https://github.com/steipete/OpenClaw.git
cd OpenClaw
npm install</code></pre>

<h2>3. Configure</h2>
<p>Copy the example config and add your API keys:</p>
<pre><code>cp .env.example .env
# Edit .env with your API keys</code></pre>

<h2>4. Run</h2>
<pre><code>npm start</code></pre>

<h2>5. Connect Your Apps</h2>
<p>OpenClaw works with:</p>
<ul>
  <li>Gmail (for email automation)</li>
  <li>Google Calendar (for scheduling)</li>
  <li>Notion (for knowledge base)</li>
  <li>WhatsApp & Telegram (for messaging)</li>
</ul>

<p>Follow the prompts to connect each service.</p>

<p><strong>Need Help?</strong> Reply to this email if you get stuck. We're here to help!</p>
`;

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { email } = req.body;

  if (!email || !email.includes('@')) {
    return res.status(400).json({ error: 'Invalid email' });
  }

  const errors: string[] = [];

  // 1. Save to Notion
  if (NOTION_API_KEY) {
    try {
      const notionRes = await fetch(NOTION_API, {
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
      if (!notionRes.ok) {
        const text = await notionRes.text();
        console.error('Notion error:', text);
        errors.push('Notion save failed');
      }
    } catch (e) {
      console.error('Notion exception:', e);
      errors.push('Notion exception');
    }
  }

  // 2. Send email via Resend
  if (RESEND_API_KEY) {
    try {
      const resendRes = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${RESEND_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: 'OpenClaw <noreply@weblydev.com>',
          to: email,
          subject: 'Your OpenClaw Setup Guide',
          html: SETUP_GUIDE,
        }),
      });
      if (!resendRes.ok) {
        const text = await resendRes.text();
        console.error('Resend error:', text);
        errors.push('Email send failed: ' + text);
      } else {
        const data = await resendRes.json();
        console.log('Resend success:', data);
      }
    } catch (e) {
      console.error('Resend exception:', e);
      errors.push('Email exception');
    }
  }

  if (errors.length > 0) {
    return res.status(500).json({ error: errors.join(', ') });
  }

  return res.status(200).json({ success: true });
}
