FROM node:14-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install && \
    npm install -g pm2 && \
    npm cache clean --force 

COPY . .
EXPOSE 5000

CMD ["pm2-runtime", "start", "index.js"]
