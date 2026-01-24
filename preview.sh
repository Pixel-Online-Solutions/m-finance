#!/bin/bash
# preview.sh - Automatyczne udostępnianie strony M-Finance
# Uruchom: ./preview.sh

# ===== KONFIGURACJA =====
PROJECT_DIR="$HOME/projekty/m-finance"
PORT="4321"
NGROK_REGION="eu"  # eu, us, ap, au, sa, jp, in

# Kolory dla wyjścia
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ===== FUNKCJE =====
print_header() {
    echo -e "${BLUE}"
    echo "========================================"
    echo "🚀  UDOSTĘPNIANIE STRONY M-FINANCE"
    echo "========================================"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

cleanup() {
    echo -e "\n🧹 ${YELLOW}Czyszczenie procesów...${NC}"
    
    if [ -n "$SERVER_PID" ] && ps -p "$SERVER_PID" > /dev/null; then
        kill "$SERVER_PID" 2>/dev/null
        print_success "Zatrzymano http-server"
    fi
    
    if [ -n "$NGROK_PID" ] && ps -p "$NGROK_PID" > /dev/null; then
        kill "$NGROK_PID" 2>/dev/null
        print_success "Zatrzymano ngrok"
    fi
    
    # Zabij procesy na porcie jeśli wiszą
    if lsof -ti:$PORT >/dev/null 2>&1; then
        kill $(lsof -ti:$PORT) 2>/dev/null
    fi
    
    echo -e "${GREEN}✨ Wszystko wyczyszczone!${NC}"
    exit 0
}

check_dependencies() {
    print_info "Sprawdzanie zależności..."
    
    # Sprawdź Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js nie jest zainstalowany!"
        exit 1
    fi
    
    # Sprawdź pnpm
    if ! command -v pnpm &> /dev/null; then
        print_error "pnpm nie jest zainstalowany! Używam npm..."
        USE_NPM=true
    else
        USE_NPM=false
    fi
    
    # Sprawdź http-server
    if ! command -v http-server &> /dev/null; then
        print_info "Instalowanie http-server..."
        npm install -g http-server
    fi
    
    # Sprawdź ngrok
    if ! command -v ngrok &> /dev/null; then
        print_error "ngrok nie jest zainstalowany!"
        echo "Zainstaluj:"
        echo "  curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null"
        echo "  echo 'deb https://ngrok-agent.s3.amazonaws.com bookworm main' | sudo tee /etc/apt/sources.list.d/ngrok.list"
        echo "  sudo apt update && sudo apt install ngrok"
        exit 1
    fi
    
    print_success "Wszystkie zależności gotowe"
}

build_project() {
    print_info "Budowanie projektu..."
    cd "$PROJECT_DIR" || exit 1
    
    if [ "$USE_NPM" = true ]; then
        npm run build
    else
        pnpm build
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Build zakończony pomyślnie"
    else
        print_error "Build nie powiódł się!"
        exit 1
    fi
}

start_server() {
    print_info "Uruchamianie serwera na porcie $PORT..."
    
    # Sprawdź czy port jest wolny
    if lsof -ti:$PORT >/dev/null 2>&1; then
        print_info "Port $PORT jest zajęty, zwalniam..."
        kill $(lsof -ti:$PORT) 2>/dev/null
        sleep 2
    fi
    
    # Uruchom http-server
    http-server dist -p $PORT -a 0.0.0.0 -c-1 --silent &
    SERVER_PID=$!
    
    sleep 3
    
    # Sprawdź czy serwer działa
    if curl -s http://localhost:$PORT > /dev/null; then
        print_success "Serwer działa: http://localhost:$PORT"
    else
        print_error "Serwer nie odpowiada!"
        exit 1
    fi
}

start_ngrok() {
    print_info "Uruchamianie ngrok..."
    
    # Uruchom ngrok w tle
    ngrok http $PORT --region $NGROK_REGION --log stdout > /tmp/ngrok_output.txt &
    NGROK_PID=$!
    
    sleep 5
    
    # Pobierz URL z output ngrok
    NGROK_URL=$(grep -o "https://[a-zA-Z0-9.-]*\.ngrok-free\.dev" /tmp/ngrok_output.txt | head -1)
    
    if [ -n "$NGROK_URL" ]; then
        echo -e "${GREEN}"
        echo "========================================"
        echo "🌐  STRONA UDOSTĘPNIONA!"
        echo "========================================"
        echo ""
        echo "📱 Link publiczny:"
        echo "   $NGROK_URL"
        echo ""
        echo "🔗 Podstrony:"
        echo "   $NGROK_URL/o-nas"
        echo "   $NGROK_URL/kontakt"
        echo "   $NGROK_URL/ksiegowosc-dla-firm"
        echo ""
        echo "📊 Panel ngrok:"
        echo "   http://127.0.0.1:4040"
        echo ""
        echo "🛑 Aby zatrzymać: naciśnij Ctrl+C"
        echo "========================================"
        echo -e "${NC}"
        
        # Zapisz link do pliku
        echo "$(date): $NGROK_URL" >> "$PROJECT_DIR/ngrok-links.txt"
        print_info "Link zapisany do: $PROJECT_DIR/ngrok-links.txt"
        
        # Skopiuj link do schowka (jeśli masz xclip)
        if command -v xclip &> /dev/null; then
            echo "$NGROK_URL" | xclip -selection clipboard
            print_info "Link skopiowany do schowka!"
        fi
    else
        print_error "Nie udało się uzyskać linku ngrok!"
        print_info "Sprawdzam logi..."
        tail -20 /tmp/ngrok_output.txt
    fi
}

# ===== GŁÓWNY PROGRAM =====
trap cleanup INT TERM

print_header
check_dependencies
build_project
start_server
start_ngrok

print_info "Czekam na zakończenie... (Ctrl+C aby zatrzymać)"

# Czekaj na zakończenie ngrok
wait $NGROK_PID

# Jeśli ngrok się zakończył, wyczyść
cleanup
