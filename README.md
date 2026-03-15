# LocHawk 
**LocHawk** is a powerful geolocation phishing tool that tricks targets into revealing their exact GPS location, device information, and network details through a seemingly harmless webpage.

---

## Security Research & Educational Purpose

LocHawk is developed for **security research, penetration testing, and educational purposes**. The tool demonstrates how social engineering and browser APIs can be used to obtain sensitive information such as **GPS location** (via the Geolocation API), **device details** (via browser APIs), and **network information** (via public APIs).

The purpose of this project is to help **cybersecurity students, researchers, and developers** understand how geolocation phishing attacks work in real-world scenarios. By studying these techniques, security professionals can design stronger defenses, improve user awareness, and build systems that better protect user privacy.

This project aims to promote **responsible security research and awareness** about the risks associated with granting location **permissions** on websites.

---

## ⚠️ DISCLAIMER — Legal and Ethical Use Notice

This tool is provided for **educational purposes, security research, and authorized security testing only**.

**Unauthorized use is illegal and may result in criminal and civil penalties.**

By downloading, installing, or using this software, you agree that:

- You will use it **only on devices, systems, or networks you own** or have **explicit written permission** from the lawful owner to test.
- You will comply with **all applicable local, state, national, and international laws** related to privacy, surveillance, data protection, and computer access.
- You are **fully responsible** for how you use this tool and for any data you collect, store, or share.
- Any attempt to access location data, devices, networks, or personal information **without authorization is illegal** and may result in criminal and civil penalties.
- This software is provided **“as is”**, without any warranties or guarantees of any kind.
- The developer **assumes no liability** for misuse, damages, legal consequences, or losses resulting from the use of this software.

This tool is intended to help security professionals, students, and researchers **understand security risks and improve defenses** — not to track, monitor, or target individuals.

If you do not agree to these terms, **do not use this software**.

*Use responsibly. Act ethically. Follow the law.*

---

##  Features

### **Location Tracking**
- Live GPS coordinates with Google Maps link
- High accuracy mode (5-50m precision)
- IP-based city/country fallback

###  **Stealth Mode**
- Zero console logs or visible elements
- Auto-executes on page load
- Silent error handling

###  **Device Info**
- Browser, OS, platform detection
- RAM, CPU cores, screen resolution
- Language, cookies, referrer

### **Network Info**
- Public IP address
- ISP, country, city
- Network-based coordinates

### **Delivery Methods**
- **Serveo.net** – Instant SSH tunnel
- **Cloudflared** – Secure HTTPS tunnel with SSL
- **Localhost Mode** – Run the server locally and use your own VPS or external tunneling service

###  **Live Monitoring**
- Auto-save to data.txt (JSON)
- Previous data preview

### **Custom Pages**
- Use your own HTML/CSS
- Internal JavaScript & CSS only
- Auto script injection
- Preserves your design

### **Data Control**
- Prompt to clear data.txt on exit
- Choose to keep or delete collected data
- Preview last 20 entries during monitoring

### **Automatic Setup**
- Automatically checks what’s needed to run
- Installs anything missing for you
- Runs once, no extra steps later
- Just start and it works

---

##  Installation
**What You Need:**

- **Linux (Debian, RHEL, Arch**) (`Kali, Parrot, Ubuntu, Black Arch, Fedora, etc`.)
- **npm** (required for install `express.js`. if it is not installed it will automatically install `npm`)
- **Node.js and expressjs** ( In linux distributions like `Debian`,`RHEL`, `Arch` it automatically install `nodejs` and `expressjs` if it is not installed)
- **Port Forwarding Options:**

  - **Serveo.net** – Used as the default option for tunneling.

  - **Cloudflared** – Available as an alternative for port forwarding and automatically installed if missing.

  - **Localhost Mode** – Runs the server locally and displays the active port, allowing users to use their own VPS or external tunneling services.
  
**Steps to Install:**
1. **Clone the repository**
```bash
git clone https://github.com/s-r-e-e-r-a-j/LocHawk.git
```
2. **Navigate to the LocHawk directory**
```bash  
cd LocHawk
```
3. **Navigate to the lochawk directory**
```bash
cd lochawk
```
4. **Start the tool**
```bash   
bash lochawk.sh
```

---

##  How to Use
1. **Run the tool**:

```bash
bash lochawk.sh
```
**OR**

```bash
chmod +x lochawk.sh
./lochawk.sh
```

2. **Choose a custom HTML page** – Optionally provide your own phishing page.

    - Internal CSS (`<style>` tags) supported

    -  Internal JavaScript (`<script>` tags) supported

    -  External CSS/JS files (links to `.css` or `.js`) are not supported

    - Your design is preserved, tracking script is auto-injected

    - Press Enter to use the default page

 **Example custom page:**
```html
html
<!DOCTYPE html>
<html>
<head>
    <style>
        /* Internal CSS only */
        body { font-family: Arial; background: #f0f0f0; }
        .container { padding: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Your Phishing Page</h1>
        <p>Content here</p>
    </div>
    <script>
        // Internal JavaScript only
        console.log("Page loaded");
    </script>
</body>
</html>
```
3. **Choose a port forwarding method** – Select `Serveo.net`, `Cloudflared`, or `Localhost` mode for manual/external tunneling.

4. Share the generated link with the target.

5. **Data Collection** – When they open the link:

   - Device details are captured automatically

   - IP address and network info are collected

   - If they allow location permission and GPS is on, exact coordinates are sent

   - All data appears in your terminal in real-time with Google Maps links

6. **Exit & Clean Up** – Press `Ctrl+C` to stop the server. You'll be prompted:

```text
[+] Do you want to clear the data file (data.txt)? (y/n):
```

  - Type `y` or `yes` to delete all collected data

  - Type `n` or `no` to keep the data file for later use

---

## License
This project is licensed under the MIT License.
