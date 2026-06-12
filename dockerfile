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

# IMPORTANT: do NOT use "yarn build" here because CIPP's build script removes package.json/yarn.lock
RUN ./node_modules/.bin/next build

FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/next.config.js ./next.config.js
COPY --from=build /app/node_modules ./node_modules

EXPOSE 3000

CMD ["./node_modules/.bin/next", "start", "-p", "3000"]
``
