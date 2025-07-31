# Use a slim Debian base image
FROM debian:bullseye-slim

# Install dependencies for steamcmd and the ARK server
RUN apt update && \
    # "apt install software-properties-common" not needed
    # "apt-add-repository non-free" now sed command
    sed -i 's/main/main contrib non-free/' /etc/apt/sources.list && \
    dpkg --add-architecture i386 && \
    apt update && \
    apt install -y \
        # For downloading steamcmd
        curl \                  
        # 32-bit libraries required by steamcmd
        lib32gcc \           
        # For SSL/TLS support
        ca-certificates \
        # For locale support
        locales

# Create a non-root user for security
RUN useradd -m -s /bin/bash steam && \
    mkdir -p /home/steam/steamcmd /ark && \
    chown -R steam:steam /home/steam /ark

# Generate en_US.UTF-8 locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Switch to the non-root user
USER steam
WORKDIR /home/steam

# Download and install SteamCMD
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zx -C /home/steam/steamcmd

# Set working directory for the server files
WORKDIR /ark

# Copy the server start script and give it execution permissions
COPY --chown=steam:steam start_server.sh .
RUN chmod +x ./start_server.sh

# Expose ARK server ports
# 7777/udp: Game Port
# 7778/udp: Game Port
# 27015/udp: Server Query Port
EXPOSE 7777/udp 7778/udp 27015/udp

# Set the entrypoint script
ENTRYPOINT [ "./start_server.sh" ]