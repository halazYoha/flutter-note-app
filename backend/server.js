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

// GET /note/:noteId - Tries to open the app, otherwise redirects directly to Play Store
app.get('/note/:noteId', (req, res) => {
    const { noteId } = req.params;
    const deepLink = `noteapp://note/${noteId}`;
    const playStoreUrl = `https://play.google.com/store/apps/details?id=com.example.note_app`;

    // Minimal HTML that immediately tries the deep link,
    // then auto-redirects to the Play Store after 1 second
    res.send(`<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Redirecting...</title>
</head>
<body>
    <script>
        // Immediately try to open the app via deep link
        window.location.href = '${deepLink}';
        // If the app is not installed, the deep link will fail silently.
        // After 1 second, redirect straight to Play Store.
        setTimeout(function() {
            window.location.replace('${playStoreUrl}');
        }, 1000);
    </script>
</body>
</html>`);
});


app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
