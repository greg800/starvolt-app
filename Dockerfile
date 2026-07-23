FROM node:20-alpine
WORKDIR /app

# Copie uniquement les fichiers nécessaires au serveur
COPY server.js starvolt.html ./
COPY *.png ./
COPY *.jpg ./
COPY *.svg ./
COPY sw.js manifest.json ./
# Données métier servies à l'app (référence DPE du bilan IA, etc.)
COPY bilan-dpe-reference.md ./

EXPOSE 8080
CMD ["node", "server.js"]
