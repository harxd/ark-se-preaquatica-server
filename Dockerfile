# Use a slim Debian base image
FROM debian:bullseye-slim

# Install dependencies for steamcmd and the ARK server
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    lib32gcc-s1 \
    ca-certificates

# Create a non-root user for security
RUN useradd -m -s /bin/bash steam && \
    mkdir -p /home/steam/steamcmd /ark && \
    chown -R steam:steam /home/steam /ark

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
# 7778/udp: Query Port
# 27015/tcp: RCON Port
EXPOSE 7777/udp 7778/udp 27015/tcp

# Set the entrypoint script
ENTRYPOINT [ "./start_server.sh" ]