# Dockerfile otimizado para Dokploy
FROM node:20-alpine AS base

# Instalar dependências do sistema
RUN apk add --no-cache libc6-compat postgresql-client

# Construção do shared package
FROM base AS shared-builder
WORKDIR /app/shared
COPY shared/package*.json ./
RUN npm ci
COPY shared/ ./
RUN npm run build

# Construção do backend
FROM base AS backend-builder
WORKDIR /app
COPY --from=shared-builder /app/shared ./shared

WORKDIR /app/server
COPY server/package*.json ./
RUN npm ci
COPY server/ ./
RUN npm run build

# Construção do frontend
FROM base AS frontend-builder
WORKDIR /app
COPY --from=shared-builder /app/shared ./shared

WORKDIR /app/client
COPY client/package*.json ./
RUN npm ci --legacy-peer-deps
COPY client/ ./

# Build args para Next.js
ARG NEXT_PUBLIC_BACKEND_URL=http://localhost:3001
ARG NEXT_PUBLIC_DISABLE_SIGNUP=false
ARG NEXT_PUBLIC_CLOUD=false

ENV NEXT_PUBLIC_BACKEND_URL=${NEXT_PUBLIC_BACKEND_URL}
ENV NEXT_PUBLIC_DISABLE_SIGNUP=${NEXT_PUBLIC_DISABLE_SIGNUP}
ENV NEXT_PUBLIC_CLOUD=${NEXT_PUBLIC_CLOUD}
ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build

# Imagem final de produção
FROM node:20-alpine AS production

# Instalar dependências do sistema
RUN apk add --no-cache postgresql-client nginx supervisor wget

# Criar usuário não-root
RUN addgroup --system --gid 1001 appuser && \
    adduser --system --uid 1001 appuser

WORKDIR /app

# Copiar aplicação backend
COPY --from=backend-builder --chown=appuser:appuser /app/server/package*.json ./server/
COPY --from=backend-builder --chown=appuser:appuser /app/server/dist ./server/dist
COPY --from=backend-builder --chown=appuser:appuser /app/server/node_modules ./server/node_modules
COPY --from=backend-builder --chown=appuser:appuser /app/server/GeoLite2-City.mmdb ./server/GeoLite2-City.mmdb
COPY --from=backend-builder --chown=appuser:appuser /app/server/public ./server/public
COPY --from=backend-builder --chown=appuser:appuser /app/server/drizzle.config.ts ./server/drizzle.config.ts
COPY --from=backend-builder --chown=appuser:appuser /app/server/src ./server/src
COPY --from=shared-builder --chown=appuser:appuser /app/shared ./shared

# Copiar aplicação frontend
COPY --from=frontend-builder --chown=appuser:appuser /app/client/.next/standalone ./client/
COPY --from=frontend-builder --chown=appuser:appuser /app/client/.next/static ./client/.next/static
COPY --from=frontend-builder --chown=appuser:appuser /app/client/public ./client/public

# Configurar nginx para servir como proxy reverso
RUN mkdir -p /var/log/nginx /var/lib/nginx/tmp /var/log/supervisor /run/nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Configurar supervisor
RUN mkdir -p /etc/supervisor/conf.d
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Scripts de entrada
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY server/docker-entrypoint.sh /server-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh /server-entrypoint.sh

# Configurar permissões
RUN chown -R appuser:appuser /app /var/log/nginx /var/lib/nginx /var/log/supervisor && \
    chmod 755 /var/lib/nginx /run/nginx && \
    touch /var/run/nginx.pid && \
    chown appuser:appuser /var/run/nginx.pid

# Expor porta 80 (nginx proxy)
EXPOSE 80

# Usar supervisor para gerenciar múltiplos serviços
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
