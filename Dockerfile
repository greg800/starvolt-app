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

# Numéro de build = SHA du commit, fourni par Railway au build (ARG). Baké en
# ENV pour que server.js l'injecte dans le HTML (journal des erreurs). Railway
# peut aussi l'injecter au runtime, qui prime alors sur cette valeur par défaut.
ARG RAILWAY_GIT_COMMIT_SHA=""
ENV RAILWAY_GIT_COMMIT_SHA=${RAILWAY_GIT_COMMIT_SHA}

EXPOSE 8080
CMD ["node", "server.js"]
