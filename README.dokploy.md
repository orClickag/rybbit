# Deploy no Dokploy

Este guia explica como fazer o deploy do Rybbit no Dokploy.

## Configuração Inicial

1. **Clone o repositório** no seu servidor Dokploy ou use o Git integration

2. **Configure as variáveis de ambiente**:
   - Use `env.dokploy.example` como referência
   - Configure no painel do Dokploy (não precisa criar arquivo .env):

```env
BASE_URL=https://yourdomain.com
BETTER_AUTH_SECRET=generate-a-strong-secret-key
POSTGRES_USER=your-postgres-user
POSTGRES_PASSWORD=your-postgres-password
CLICKHOUSE_PASSWORD=your-clickhouse-password
DISABLE_SIGNUP=false
NEXT_PUBLIC_CLOUD=false
```

**⚠️ Importante**: Gere uma chave secreta forte para `BETTER_AUTH_SECRET`

## Deploy no Dokploy

### Opção 1: Docker Compose (Recomendado)

1. **No painel do Dokploy**:
   - Clique em "Create Application" 
   - Escolha "Compose"
   - Conecte seu repositório Git

2. **Configuração**:
   - **Build Path**: `/` (raiz do projeto)
   - **Compose File**: `docker-compose.dokploy.yml`
   - **Port**: `80` (será mapeada automaticamente para HTTPS)

3. **Variáveis de Ambiente**:
   Configure as seguintes variáveis no painel:
   ```
   BASE_URL=https://seudominio.com
   BETTER_AUTH_SECRET=uma-chave-secreta-forte-aqui
   POSTGRES_USER=rybbit_user
   POSTGRES_PASSWORD=sua-senha-segura
   CLICKHOUSE_PASSWORD=outra-senha-segura
   ```

4. **Deploy**:
   - Clique em "Deploy"
   - Aguarde o build e inicialização dos serviços

### Opção 2: Container Único (Para casos específicos)

1. **No painel do Dokploy**:
   - Clique em "Create Application"
   - Escolha "Docker"
   - Conecte seu repositório Git

2. **Configuração**:
   - **Build Path**: `/` (raiz do projeto)
   - **Dockerfile**: `Dockerfile` (na raiz)
   - **Port**: `80`

3. **Bancos de Dados**:
   Configure PostgreSQL, ClickHouse e Redis como serviços separados no Dokploy

4. **Variáveis de Ambiente**:
   Além das variáveis básicas, configure também as conexões dos bancos

## Variáveis de Ambiente Importantes

### Obrigatórias
- `BASE_URL`: URL completa do seu site (ex: https://analytics.seusite.com)
- `BETTER_AUTH_SECRET`: Chave secreta para autenticação (gere uma forte)
- `POSTGRES_USER`: Usuário do PostgreSQL
- `POSTGRES_PASSWORD`: Senha do PostgreSQL
- `CLICKHOUSE_PASSWORD`: Senha do ClickHouse

### Opcionais
- `DISABLE_SIGNUP=true`: Desabilita registro de novos usuários
- `DISABLE_TELEMETRY=true`: Desabilita telemetria
- `NEXT_PUBLIC_CLOUD=true`: Ativa recursos cloud

## Portas

A aplicação expõe a porta 80 internamente. O Dokploy irá mapear automaticamente para HTTPS.

## Volumes Persistentes

Certifique-se que os seguintes volumes sejam persistentes:
- `clickhouse-data`: Dados do ClickHouse
- `postgres-data`: Dados do PostgreSQL
- `redis-data`: Dados do Redis

## Health Checks

A aplicação inclui health checks em `/health` para garantir que está funcionando corretamente.

## Logs

Os logs podem ser visualizados através do painel do Dokploy ou via:
- Backend: `/var/log/supervisor/backend.*.log`
- Frontend: `/var/log/supervisor/frontend.*.log`
- Nginx: `/var/log/nginx/*.log`

## Troubleshooting

### Problema de Permissões
Se houver problemas de permissão, verifique se o usuário `appuser` tem as permissões corretas.

### Problemas de Conexão com Banco
Verifique se as variáveis de ambiente dos bancos estão corretas e se os serviços estão rodando.

### Problemas de Build
Certifique-se de que todos os arquivos necessários estão no contexto de build.

## Comandos Úteis

```bash
# Verificar logs
docker-compose -f docker-compose.dokploy.yml logs app

# Reiniciar aplicação
docker-compose -f docker-compose.dokploy.yml restart app

# Executar migrações manualmente
docker-compose -f docker-compose.dokploy.yml exec app sh -c "cd /app/server && npm run db:migrate"
```
