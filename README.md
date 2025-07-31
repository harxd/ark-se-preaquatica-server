# ARK: Survival Evolved (Pre-Aquatic) Docker Server

This project provides a simple way to run a dedicated ARK: Survival Evolved server for the `preaquatic` beta branch using Docker and Docker Compose.

## Features

-   **Pre-Aquatic Branch**: Downloads the specific beta version of ARK.
-   **Auto-Updates**: Checks for server and mod updates every time the container starts.
-   **Easy Configuration**: All major server settings are controlled via environment variables in the `docker-compose.yml` file.
-   **Mod Support**: Automatically downloads and updates specified workshop mods.
-   **Data Persistence**: Server data, configs, and worlds are stored in a Docker volume, so they are safe across container restarts.

## Prerequisites

-   [Docker](https://docs.docker.com/get-docker/)
-   [Docker Compose](https://docs.docker.com/compose/install/)

## How to Use

1.  **Clone or Download**: Place all the project files (`Dockerfile`, `start_server.sh`, `docker-compose.yml`) into a single directory on your machine.

2.  **Configure Your Server**:
    Open the `docker-compose.yml` file and edit the `environment` variables to your liking.

    | Variable          | Description                                                    | Default                             |
    | ----------------- | -------------------------------------------------------------- | ----------------------------------- |
    | `SESSION_NAME`    | The name of your server as it appears in the server list.      | `ARK Pre-Aquatic Docker`            |
    | `SERVER_MAP`      | The map to load (e.g., `TheIsland`, `ScorchedEarth_P`).         | `TheIsland`                         |
    | `SERVER_PASSWORD` | The password players need to enter to join. Leave blank for none. | `""` (none)                         |
    | `ADMIN_PASSWORD`  | The password required for admin commands (`enablecheats`).     | A randomly generated 12-char string |
    | `MAX_PLAYERS`     | The maximum number of players allowed on the server.           | `20`                                |
    | `DISABLE_BATTLEYE`| Set to `true` to disable BattlEye anti-cheat.                  | `true`                              |
    | `GAME_MOD_IDS`    | A comma-separated list of Steam Workshop Mod IDs.              | `""` (none)                         |

3.  **Start the Server**:
    Open a terminal in the project directory and run the following command. The `-d` flag runs it in the background.

    ```bash
    docker-compose up -d
    ```

    The first time you run this, it will download the base image and the ARK server files, which can take a significant amount of time and disk space (~20-30GB).

4.  **View Logs**:
    To see the server's console output (including the generated admin password on first run), use:

    ```bash
    docker-compose logs -f
    ```

5.  **Stop the Server**:
    To stop the server and the container, run:

    ```bash
    docker-compose down
    ```
    Your game data will be saved in the Docker volume and will be available the next time you start the server.