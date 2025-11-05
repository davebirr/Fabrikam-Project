using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using FabrikamApi.Models;
using FabrikamApi.Models.Authentication;

namespace FabrikamApi.Data;

/// <summary>
/// Extended DbContext that combines Fabrikam business data with ASP.NET Identity
/// Provides unified data access for both business operations and authentication
/// </summary>
public class FabrikamIdentityDbContext : IdentityDbContext<FabrikamUser, FabrikamRole, string, FabrikamUserClaim, FabrikamUserRole, IdentityUserLogin<string>, IdentityRoleClaim<string>, IdentityUserToken<string>>
{
    public FabrikamIdentityDbContext(DbContextOptions<FabrikamIdentityDbContext> options) : base(options)
    {
    }

    // Fabrikam Business Entities
    public DbSet<Customer> Customers { get; set; }
    public DbSet<Product> Products { get; set; }
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderItem> OrderItems { get; set; }
    public DbSet<SupportTicket> SupportTickets { get; set; }
    public DbSet<TicketNote> TicketNotes { get; set; }
    
    // Supplier Invoice Management
    public DbSet<Invoice> Invoices { get; set; }
    public DbSet<InvoiceLineItem> InvoiceLineItems { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Determine if we're using InMemory database for conditional configuration
        var isInMemory = Database.IsInMemory();

        // Configure ASP.NET Identity table names with "Fab" prefix to avoid conflicts
        modelBuilder.Entity<FabrikamUser>().ToTable("FabUsers");
        modelBuilder.Entity<FabrikamRole>().ToTable("FabRoles");
        modelBuilder.Entity<FabrikamUserClaim>().ToTable("FabUserClaims");
        modelBuilder.Entity<FabrikamUserRole>().ToTable("FabUserRoles");
        modelBuilder.Entity<IdentityUserLogin<string>>().ToTable("FabUserLogins");
        modelBuilder.Entity<IdentityRoleClaim<string>>().ToTable("FabRoleClaims");
        modelBuilder.Entity<IdentityUserToken<string>>().ToTable("FabUserTokens");

        // Configure FabrikamUser extensions
        modelBuilder.Entity<FabrikamUser>(entity =>
        {
            entity.Property(u => u.FirstName)
                .HasMaxLength(50)
                .IsRequired();

            entity.Property(u => u.LastName)
                .HasMaxLength(50)
                .IsRequired();

            entity.Property(u => u.NotificationPreferences)
                .HasMaxLength(100)
                .HasDefaultValue("email");

            // Use conditional default value configuration based on database provider
            if (!isInMemory)
            {
                entity.Property(u => u.CreatedDate)
                    .HasDefaultValueSql("GETUTCDATE()");
            }
            else
            {
                entity.Property(u => u.CreatedDate)
                    .HasDefaultValue(DateTime.UtcNow);
            }

            entity.Property(u => u.IsActive)
                .HasDefaultValue(true);

            entity.Property(u => u.IsAdmin)
                .HasDefaultValue(false);

            // Index for performance
            entity.HasIndex(u => u.Email)
                .IsUnique();

            entity.HasIndex(u => new { u.FirstName, u.LastName });
            entity.HasIndex(u => u.CustomerId);
            entity.HasIndex(u => u.IsActive);
        });

        // Configure FabrikamRole extensions
        modelBuilder.Entity<FabrikamRole>(entity =>
        {
            entity.Property(r => r.Description)
                .HasMaxLength(200);

            // Use conditional default value configuration
            if (!isInMemory)
            {
                entity.Property(r => r.CreatedDate)
                    .HasDefaultValueSql("GETUTCDATE()");
            }
            else
            {
                entity.Property(r => r.CreatedDate)
                    .HasDefaultValue(DateTime.UtcNow);
            }

            entity.Property(r => r.IsActive)
                .HasDefaultValue(true);

            entity.Property(r => r.Priority)
                .HasDefaultValue(100);

            entity.HasIndex(r => r.IsActive);
            entity.HasIndex(r => r.Priority);
        });

        // Configure FabrikamUserClaim extensions
        modelBuilder.Entity<FabrikamUserClaim>(entity =>
        {
            // Use conditional default value configuration
            if (!isInMemory)
            {
                entity.Property(c => c.GrantedDate)
                    .HasDefaultValueSql("GETUTCDATE()");
            }
            else
            {
                entity.Property(c => c.GrantedDate)
                    .HasDefaultValue(DateTime.UtcNow);
            }

            entity.Property(c => c.GrantedBy)
                .HasMaxLength(256);

            entity.Property(c => c.IsActive)
                .HasDefaultValue(true);

            entity.HasIndex(c => c.IsActive);
            entity.HasIndex(c => c.ExpiresDate);
        });

        // Configure FabrikamUserRole audit extensions
        modelBuilder.Entity<FabrikamUserRole>(entity =>
        {
            // Use conditional default value configuration
            if (!isInMemory)
            {
                entity.Property(ur => ur.AssignedAt)
                    .HasDefaultValueSql("GETUTCDATE()");
            }
            else
            {
                entity.Property(ur => ur.AssignedAt)
                    .HasDefaultValue(DateTime.UtcNow);
            }

            entity.Property(ur => ur.AssignedBy)
                .HasMaxLength(256);

            entity.Property(ur => ur.AssignmentNotes)
                .HasMaxLength(500);

            entity.Property(ur => ur.IsActive)
                .HasDefaultValue(true);

            // Create indexes for performance
            entity.HasIndex(ur => ur.AssignedAt);
            entity.HasIndex(ur => ur.IsActive);
            entity.HasIndex(ur => ur.ExpiresAt);
        });

        // Configure User-Customer relationship
        modelBuilder.Entity<FabrikamUser>()
            .HasOne(u => u.Customer)
            .WithMany() // A customer might have multiple user accounts
            .HasForeignKey(u => u.CustomerId)
            .OnDelete(DeleteBehavior.SetNull);

        // Configure decimal precision for financial fields (conditional for SQL Server)
        if (!isInMemory)
        {
            modelBuilder.Entity<Product>()
                .Property(p => p.Price)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Order>()
                .Property(o => o.Subtotal)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Order>()
                .Property(o => o.Tax)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Order>()
                .Property(o => o.Shipping)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Order>()
                .Property(o => o.Total)
                .HasPrecision(18, 2);

            modelBuilder.Entity<OrderItem>()
                .Property(oi => oi.UnitPrice)
                .HasPrecision(18, 2);

            modelBuilder.Entity<OrderItem>()
                .Property(oi => oi.LineTotal)
                .HasPrecision(18, 2);
        }

        // Configure business entity relationships
        modelBuilder.Entity<Order>()
            .HasOne(o => o.Customer)
            .WithMany(c => c.Orders)
            .HasForeignKey(o => o.CustomerId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<OrderItem>()
            .HasOne(oi => oi.Order)
            .WithMany(o => o.OrderItems)
            .HasForeignKey(oi => oi.OrderId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<OrderItem>()
            .HasOne(oi => oi.Product)
            .WithMany(p => p.OrderItems)
            .HasForeignKey(oi => oi.ProductId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<SupportTicket>()
            .HasOne(st => st.Customer)
            .WithMany(c => c.SupportTickets)
            .HasForeignKey(st => st.CustomerId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<SupportTicket>()
            .HasOne(st => st.Order)
            .WithMany()
            .HasForeignKey(st => st.OrderId)
            .OnDelete(DeleteBehavior.SetNull);

        modelBuilder.Entity<TicketNote>()
            .HasOne(tn => tn.Ticket)
            .WithMany(st => st.Notes)
            .HasForeignKey(tn => tn.TicketId)
            .OnDelete(DeleteBehavior.Cascade);

        // Configure unique constraints
        modelBuilder.Entity<Order>()
            .HasIndex(o => o.OrderNumber)
            .IsUnique();

        modelBuilder.Entity<SupportTicket>()
            .HasIndex(st => st.TicketNumber)
            .IsUnique();

        modelBuilder.Entity<Product>()
            .HasIndex(p => p.ModelNumber)
            .IsUnique();

        // Configure indexes for better query performance
        modelBuilder.Entity<Order>()
            .HasIndex(o => new { o.CustomerId, o.OrderDate });

        modelBuilder.Entity<Order>()
            .HasIndex(o => o.Status);

        modelBuilder.Entity<SupportTicket>()
            .HasIndex(st => new { st.CustomerId, st.Status });

        modelBuilder.Entity<SupportTicket>()
            .HasIndex(st => st.CreatedDate);

        modelBuilder.Entity<Product>()
            .HasIndex(p => p.Category);

        // Configure Invoice relationships
        modelBuilder.Entity<Invoice>()
            .HasIndex(i => i.InvoiceNumber)
            .IsUnique();

        modelBuilder.Entity<Invoice>()
            .HasIndex(i => i.Vendor);

        modelBuilder.Entity<Invoice>()
            .HasIndex(i => i.Status);

        modelBuilder.Entity<Invoice>()
            .HasIndex(i => i.InvoiceDate);

        modelBuilder.Entity<Invoice>()
            .HasIndex(i => new { i.Vendor, i.TotalAmount, i.InvoiceDate });

        modelBuilder.Entity<InvoiceLineItem>()
            .HasOne(ili => ili.Invoice)
            .WithMany(i => i.LineItems)
            .HasForeignKey(ili => ili.InvoiceId)
            .OnDelete(DeleteBehavior.Cascade);

        // Configure decimal precision for invoice financial fields (conditional for SQL Server)
        if (!isInMemory)
        {
            modelBuilder.Entity<Invoice>()
                .Property(i => i.SubtotalAmount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Invoice>()
                .Property(i => i.TaxAmount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Invoice>()
                .Property(i => i.ShippingAmount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Invoice>()
                .Property(i => i.TotalAmount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<InvoiceLineItem>()
                .Property(ili => ili.UnitPrice)
                .HasPrecision(18, 2);

            modelBuilder.Entity<InvoiceLineItem>()
                .Property(ili => ili.Amount)
                .HasPrecision(18, 2);
        }

        // Note: Role seeding is handled by AuthenticationSeedService to avoid conflicts
        // SeedIdentityData(modelBuilder);
    }

    /// <summary>
    /// Seeds initial authentication data for the system
    /// Creates default roles and admin user
    /// Note: Currently disabled in favor of AuthenticationSeedService to prevent duplicate seeding
    /// </summary>
    private void SeedIdentityData(ModelBuilder modelBuilder)
    {
        // Variables removed - not used since seeding is disabled
        
        // Seed default roles - DISABLED to prevent conflicts with AuthenticationSeedService
        // modelBuilder.Entity<FabrikamRole>().HasData(
        //     new FabrikamRole
        //     {
        //         Id = adminRoleId,
        //         Name = "Administrator",
        //         NormalizedName = "ADMINISTRATOR",
        //         Description = "Full system access and user management",
        //         Priority = 1,
        //         CreatedDate = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc)
        //     },
        //     new FabrikamRole
        //     {
        //         Id = userRoleId,
        //         Name = "User",
        //         NormalizedName = "USER",
        //         Description = "Standard user access to business features",
        //         Priority = 100,
        //         CreatedDate = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc)
        //     },
        //     new FabrikamRole
        //     {
        //         Id = managerRoleId,
        //         Name = "Manager",
        //         NormalizedName = "MANAGER",
        //         Description = "Management access to reports and customer data",
        //         Priority = 50,
        //         CreatedDate = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc)
        //     }
        // );
    }
}
