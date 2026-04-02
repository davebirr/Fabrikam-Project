# syntax=docker/dockerfile:1
# Fabrikam API
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy csproj files and restore dependencies
COPY ["FabrikamApi/src/FabrikamApi.csproj", "FabrikamApi/src/"]
COPY ["FabrikamContracts/FabrikamContracts.csproj", "FabrikamContracts/"]
RUN dotnet restore "FabrikamApi/src/FabrikamApi.csproj"

# Copy source code and build
COPY FabrikamApi/src/ FabrikamApi/src/
COPY FabrikamContracts/ FabrikamContracts/
WORKDIR "/src/FabrikamApi/src"
RUN dotnet build "FabrikamApi.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "FabrikamApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy published app
COPY --from=publish /app/publish .

# Create non-root user
RUN useradd -m -u 1000 fabrikam && chown -R fabrikam:fabrikam /app
USER fabrikam

# Expose port (configurable via environment)
EXPOSE 8080
EXPOSE 8081

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Set environment defaults
ENV ASPNETCORE_URLS=http://+:8080 \
    ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "FabrikamApi.dll"]
