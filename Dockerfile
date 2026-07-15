FROM node:20-alpine
WORKDIR /app

# Copie uniquement les fichiers nécessaires au serveur
COPY server.js starvolt.html ./
COPY *.png ./
COPY *.jpg ./
COPY *.svg ./
COPY sw.js manifest.json ./

EXPOSE 8080
CMD ["node", "server.js"]
