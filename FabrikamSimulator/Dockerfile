# syntax=docker/dockerfile:1

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy csproj files and restore dependencies
COPY ["FabrikamSimulator/src/FabrikamSimulator.csproj", "FabrikamSimulator/src/"]
COPY ["FabrikamContracts/FabrikamContracts.csproj", "FabrikamContracts/"]
RUN dotnet restore "FabrikamSimulator/src/FabrikamSimulator.csproj"

# Copy source code and build
COPY FabrikamSimulator/src/ FabrikamSimulator/src/
COPY FabrikamContracts/ FabrikamContracts/
WORKDIR "/src/FabrikamSimulator/src"
RUN dotnet build "FabrikamSimulator.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "FabrikamSimulator.csproj" -c Release -o /app/publish /p:UseAppHost=false

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

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Set environment defaults
ENV ASPNETCORE_URLS=http://+:8080 \
    ASPNETCORE_ENVIRONMENT=Production \
    FabrikamApi__BaseUrl=http://fabrikam-api:8080

ENTRYPOINT ["dotnet", "FabrikamSimulator.dll"]
