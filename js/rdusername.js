// js/rdusername.js

document.addEventListener('DOMContentLoaded', () => {
    const generateBtn = document.getElementById('generate-btn');
    const usernameDisplay = document.getElementById('username-display');
    const copyMessage = document.getElementById('copy-message');

    const consonants = 'bcdfghjklmnpqrstvwxyz';
    const vowels = 'aeiou';

    const generateUsername = () => {
        let username = '';
        let isNextVowel = Math.random() > 0.5;

        for (let i = 0; i < 8; i++) {
            if (isNextVowel) {
                username += vowels[Math.floor(Math.random() * vowels.length)];
            } else {
                username += consonants[Math.floor(Math.random() * consonants.length)];
            }
            isNextVowel = !isNextVowel;
        }

        usernameDisplay.innerText = username;
        copyMessage.style.display = 'none';
    };

    const copyToClipboard = async () => {
        const username = usernameDisplay.innerText;
        if (!username || username === "Click button to generate") return;

        try {
            await navigator.clipboard.writeText(username);
            copyMessage.innerText = "Copied to clipboard!";
            copyMessage.style.color = "var(--primary-color)";
            copyMessage.style.display = 'block';
            setTimeout(() => {
                copyMessage.style.display = 'none';
            }, 2000);
        } catch (err) {
            console.error('Failed to copy: ', err);
            copyMessage.innerText = "Error copying!";
            copyMessage.style.color = "var(--error-color)";
            copyMessage.style.display = 'block';
            setTimeout(() => {
                copyMessage.style.display = 'none';
            }, 2000);
        }
    };

    generateBtn.addEventListener('click', generateUsername);
    usernameDisplay.addEventListener('click', copyToClipboard);

    generateUsername();
});