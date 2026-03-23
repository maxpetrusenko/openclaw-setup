import type { VercelRequest, VercelResponse } from '@vercel/node';

const NOTION_API = 'https://api.notion.com/v1/pages';
const DEFAULT_DATABASE_ID = '2fe272b567978074a480d1dc73fd3be1';
const NOTION_API_KEYS = [process.env.NOTION_API_KEY, process.env.NOTION_API_KEY2].filter(
  (key): key is string => Boolean(key),
);
const RESEND_API_KEY = process.env.RESEND_API_KEY || process.env.RESEND_API_KEY2;
const NOTION_DATABASE_ID = process.env.NOTION_DATABASE_ID || DEFAULT_DATABASE_ID;
const RESEND_FROM = process.env.RESEND_FROM || 'OpenClaw <noreply@maxpetrusenko.com>';

const EMAIL_SOURCE = 'openclaw\\resend';
const EMAIL_SUBJECT = 'Your OpenClaw Setup Guide';
const SETUP_GUIDE = `
<h1>OpenClaw Setup Guide</h1>

<p>Welcome! Here’s the fastest way to get OpenClaw running.</p>

<h2>1) Download the latest release (recommended)</h2>
<p>Get the macOS and Windows installers here:</p>
<p><a href="https://github.com/openclaw/openclaw/releases/tag/v2026.2.3">https://github.com/openclaw/openclaw/releases/tag/v2026.2.3</a></p>

<h2>2) Install (macOS)</h2>
<ol>
  <li>Download the macOS installer from the release page.</li>
  <li>Open the installer and follow the prompts.</li>
  <li>Launch OpenClaw and run the onboarding wizard.</li>
</ol>

<h2>3) Install (Windows)</h2>
<ol>
  <li>Download the Windows installer from the release page.</li>
  <li>Run the installer and follow the prompts.</li>
  <li>Launch OpenClaw and run the onboarding wizard.</li>
</ol>

<h2>4) Optional: install from source (advanced)</h2>
<pre><code>git clone https://github.com/openclaw/openclaw.git
cd openclaw
npm install
npm start</code></pre>

<h2>5) Connect your apps</h2>
<p>OpenClaw supports Gmail, Calendar, Notion, WhatsApp, and Telegram. The wizard will guide you through it.</p>

<p><strong>Need help?</strong> Reply to this email and I’ll help you get set up.</p>
`;

function stripHtml(html: string) {
  return html
    .replace(/<\s*br\s*\/?>/gi, '\n')
    .replace(/<\s*\/p\s*>/gi, '\n\n')
    .replace(/<\s*\/h[1-6]\s*>/gi, '\n\n')
    .replace(/<\s*li\s*>/gi, '- ')
    .replace(/<[^>]+>/g, '')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

function parseJsonBody(req: VercelRequest) {
  if (!req.body) {
    return null;
  }

  if (typeof req.body === 'string') {
    try {
      return JSON.parse(req.body);
    } catch {
      return null;
    }
  }

  return req.body;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const body = parseJsonBody(req) || {};
  const email = typeof body.email === 'string' ? body.email.trim() : '';

  if (!email || !email.includes('@')) {
    return res.status(400).json({ error: 'Invalid email' });
  }

  const missing: string[] = [];
  if (!RESEND_API_KEY) {
    missing.push('RESEND_API_KEY');
  }
  if (NOTION_API_KEYS.length === 0) {
    missing.push('NOTION_API_KEY');
  }
  if (!NOTION_DATABASE_ID) {
    missing.push('NOTION_DATABASE_ID');
  }
  if (missing.length > 0) {
    return res.status(500).json({
      error: `Missing server configuration: ${missing.join(', ')}`,
    });
  }

  // 1. Send email via Resend
  try {
    const resendRes = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: RESEND_FROM,
        to: email,
        subject: EMAIL_SUBJECT,
        html: SETUP_GUIDE,
      }),
    });
    if (!resendRes.ok) {
      const text = await resendRes.text();
      console.error('Resend error:', text);
      return res.status(502).json({ error: 'Email send failed' });
    }
    const data = await resendRes.json();
    console.log('Resend success:', data);
  } catch (e) {
    console.error('Resend exception:', e);
    return res.status(502).json({ error: 'Email send failed' });
  }

  // 2. Save to Notion
  try {
    let dataSourceId: string | undefined;
    let notionKey: string | undefined;
    let lastDbError: string | null = null;

    for (const key of NOTION_API_KEYS) {
      const dbRes = await fetch(`https://api.notion.com/v1/databases/${NOTION_DATABASE_ID}`, {
        headers: {
          'Authorization': `Bearer ${key}`,
          'Notion-Version': '2025-09-03',
        },
      });

      if (!dbRes.ok) {
        lastDbError = await dbRes.text();
        continue;
      }

      const dbData = await dbRes.json();
      dataSourceId = dbData.data_sources?.[0]?.id;
      if (!dataSourceId) {
        lastDbError = 'No data source found in database';
        continue;
      }
      notionKey = key;
      break;
    }

    if (!dataSourceId || !notionKey) {
      console.error('Database fetch error:', lastDbError);
      return res.status(502).json({ error: 'Notion database lookup failed', emailSent: true });
    }

    const notionRes = await fetch(NOTION_API, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${notionKey}`,
        'Content-Type': 'application/json',
        'Notion-Version': '2025-09-03',
      },
      body: JSON.stringify({
        parent: { data_source_id: dataSourceId },
        properties: {
          Source: {
            title: [{ text: { content: EMAIL_SOURCE } }],
          },
          Email: {
            email,
          },
          Subject: {
            rich_text: [{ text: { content: EMAIL_SUBJECT } }],
          },
          Body: {
            rich_text: [{ text: { content: stripHtml(SETUP_GUIDE) } }],
          },
        },
      }),
    });

    if (!notionRes.ok) {
      const text = await notionRes.text();
      console.error('Notion error:', text);
      return res.status(502).json({ error: 'Notion save failed', emailSent: true });
    }
  } catch (e) {
    console.error('Notion exception:', e);
    return res.status(502).json({ error: 'Notion save failed', emailSent: true });
  }

  return res.status(200).json({ success: true });
}
