#!/bin/sh
set -e

# Criar diretórios necessários
mkdir -p /var/log/supervisor /var/run

# Executar migrações do banco se necessário
if [ "$RUN_MIGRATIONS" = "true" ]; then
    echo "Executando migrações do banco..."
    cd /app/server
    npm run db:migrate || echo "Migrações falharam, continuando..."
fi

# Executar comando passado
exec "$@"
