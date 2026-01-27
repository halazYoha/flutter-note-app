const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Telegram Credentials
const TELEGRAM_BOT_TOKEN = "8347412984:AAER9EWg3UIP5qW-Saqwp85KvoZzPAfgUIs";
const TELEGRAM_CHAT_ID = "@flutter_notes21";

// Route to handle notification requests
app.post('/notify', async (req, res) => {
    const { title, content } = req.body;

    if (!title || !content) {
        return res.status(400).send({ error: "Title and content are required" });
    }

    console.log(`Received new note: ${title}`);

    const message = `📝 *New Note Created*\n\n*Title:* ${title}\n*Content:* ${content}`;

    try {
        const telegramRes = await axios.post(
            `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
            {
                chat_id: TELEGRAM_CHAT_ID,
                text: message,
                parse_mode: "Markdown",
            }
        );
        console.log("Telegram response:", telegramRes.data);
        console.log("Telegram notification sent!");
        res.status(200).send({ success: true, message: "Notification sent" });
    } catch (error) {
        console.error("Error sending to Telegram:", error.message);
        res.status(500).send({ error: "Failed to send notification" });
    }
});


app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
