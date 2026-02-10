const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;
app.use(cors());
app.use(bodyParser.json());


const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || "8347412984:AAER9EWg3UIP5qW-Saqwp85KvoZzPAfgUIs"; // Fallback for dev only

app.post('/notify', async (req, res) => {
    const { title, content, channel_id } = req.body;

    if (!title || !content || !channel_id) {
        return res.status(400).send({ error: "Title, content, and channel_id are required" });
    }

    console.log(`Received new note: ${title} for channel: ${channel_id}`);

    const message = `📝 *New Note Created*\n\n*Title:* ${title}\n*Content:* ${content}`;

    try {
        const telegramRes = await axios.post(
            `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
            {
                chat_id: channel_id,
                text: message,
                parse_mode: "Markdown",
            }
        );
        console.log("Telegram response:", telegramRes.data);
        console.log("Telegram notification sent!");
        res.status(200).send({ success: true, message: "Notification sent" });
    } catch (error) {
        console.error("Error sending to Telegram:", error.response?.data || error.message);
        res.status(500).send({ error: "Failed to send notification" });
    }
});

app.post('/verify-telegram', async (req, res) => {
    const { channel_username } = req.body;

    if (!channel_username) {
        return res.status(400).send({ error: "Channel username required" });
    }

    try {
        const chatRes = await axios.get(
            `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getChat`,
            { params: { chat_id: channel_username } }
        );

        const channelId = chatRes.data.result.id;
        const channelTitle = chatRes.data.result.title || channel_username;

        // OPTIONAL: send test message
        await axios.post(
            `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
            {
                chat_id: channelId,
                text: "✅ Telegram connected successfully",
            }
        );

        res.send({
            success: true,
            channel_id: channelId.toString(),
            channel_name: channelTitle,
        });

    } catch (err) {
        console.error("Verification error:", err.response?.data || err.message);
        res.status(400).send({
            success: false,
            error: "Bot is not admin or channel not accessible",
        });
    }
});

// Firebase RTDB URL
const FIREBASE_DB_URL = 'https://prime-art-eab7d-default-rtdb.firebaseio.com';

// GET /note/:noteId - Serves a redirect page that opens the app or shows the note in browser
app.get('/note/:noteId', async (req, res) => {
    const { noteId } = req.params;
    const deepLink = `noteapp://note/${noteId}`;
    const playStoreUrl = `https://play.google.com/store/apps/details?id=com.example.note_app`;

    let noteTitle = 'Teshiet Note';
    let noteContent = '';
    let noteDate = '';
    let noteTags = [];

    // Fetch note from Firebase
    try {
        const fbRes = await axios.get(`${FIREBASE_DB_URL}/notes/${noteId}.json`);
        if (fbRes.data) {
            noteTitle = fbRes.data.title || 'Untitled Note';
            noteContent = fbRes.data.content || '';
            noteDate = fbRes.data.createdDate || '';
            noteTags = fbRes.data.tags || [];
        }
    } catch (err) {
        console.error('Error fetching note from Firebase:', err.message);
    }

    // Escape HTML to prevent XSS
    const escapeHtml = (str) => str
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');

    const safeTitle = escapeHtml(noteTitle);
    const safeContent = escapeHtml(noteContent);
    const formattedDate = noteDate ? new Date(noteDate).toLocaleDateString('en-US', {
        year: 'numeric', month: 'long', day: 'numeric'
    }) : '';
    const tagsHtml = noteTags.length > 0
        ? `<div class="tags">${noteTags.map(t => `<span class="tag">${escapeHtml(t)}</span>`).join('')}</div>`
        : '';

    res.send(`<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${safeTitle} - Teshiet Notes</title>
    <meta name="description" content="${safeContent.substring(0, 160)}">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .card {
            background: white;
            border-radius: 20px;
            padding: 32px;
            max-width: 500px;
            width: 100%;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        .app-badge {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 20px;
            padding-bottom: 16px;
            border-bottom: 1px solid #eee;
        }
        .app-icon {
            width: 44px;
            height: 44px;
            background: linear-gradient(135deg, #9D8DF1, #B39DDB);
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 22px;
        }
        .app-name {
            font-size: 14px;
            color: #888;
        }
        .app-name strong {
            display: block;
            color: #333;
            font-size: 16px;
        }
        h1 {
            font-size: 24px;
            color: #1a1a2e;
            margin-bottom: 8px;
        }
        .date {
            font-size: 13px;
            color: #999;
            margin-bottom: 16px;
        }
        .content {
            font-size: 16px;
            line-height: 1.6;
            color: #444;
            white-space: pre-wrap;
            word-wrap: break-word;
            margin-bottom: 20px;
            max-height: 300px;
            overflow-y: auto;
        }
        .tags {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin-bottom: 20px;
        }
        .tag {
            background: #f0ebff;
            color: #6A5AE0;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 13px;
        }
        .btn {
            display: block;
            width: 100%;
            padding: 14px;
            border: none;
            border-radius: 14px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            text-align: center;
            text-decoration: none;
            margin-bottom: 10px;
        }
        .btn-primary {
            background: linear-gradient(135deg, #6A5AE0, #9D8DF1);
            color: white;
        }
        .btn-secondary {
            background: #f5f5f5;
            color: #333;
        }
        .status {
            text-align: center;
            font-size: 14px;
            color: #888;
            margin-top: 12px;
        }
        .spinner {
            display: inline-block;
            width: 16px;
            height: 16px;
            border: 2px solid #ddd;
            border-top-color: #6A5AE0;
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
            vertical-align: middle;
            margin-right: 6px;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
    </style>
</head>
<body>
    <div class="card">
        <div class="app-badge">
            <div class="app-icon">📝</div>
            <div class="app-name">
                <strong>Teshiet Notes</strong>
                Shared Note
            </div>
        </div>
        <h1>${safeTitle}</h1>
        ${formattedDate ? `<p class="date">${formattedDate}</p>` : ''}
        <div class="content">${safeContent || '<em>This note is empty.</em>'}</div>
        ${tagsHtml}
        <a href="${deepLink}" class="btn btn-primary" id="openApp">Open in App</a>
        <a href="${playStoreUrl}" class="btn btn-secondary">Get the App</a>
        <p class="status" id="status"><span class="spinner"></span>Trying to open in app...</p>
    </div>
    <script>
        // Try to open the app automatically
        setTimeout(function() {
            window.location.href = '${deepLink}';
        }, 300);
        // Update status after timeout
        setTimeout(function() {
            document.getElementById('status').innerHTML = 'You can read the note above, or open it in the app.';
        }, 2000);
    </script>
</body>
</html>`);
});


app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
