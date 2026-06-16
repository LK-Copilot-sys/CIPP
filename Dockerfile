FROM node:22-alpine AS deps
WORKDIR /app

COPY package.json yarn.lock ./
RUN corepack enable && yarn install --frozen-lockfile --network-timeout 500000

FROM node:22-alpine AS build
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_OPTIONS=--max-old-space-size=2048

COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN ./node_modules/.bin/next build

FROM nginx:alpine AS runner

# Static export output (next.config.js: output: 'export', distDir: './out')
COPY --from=build /app/out /usr/share/nginx/html

# Serve the static site on port 3000 with SPA-style fallback
RUN printf 'server {\n    listen 3000;\n    server_name _;\n    root /usr/share/nginx/html;\n    index index.html;\n    location / {\n        try_files $uri $uri.html $uri/ /index.html;\n    }\n}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 3000
