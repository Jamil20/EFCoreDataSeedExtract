# EFCoreDataSeedExtract
SQL script to extract data from a database table and format it for EF Core migrations

I couldn't find any repo that did something similar, so I decided to make one. Will format for the HasData syntax

eg.
            modelBuilder.Entity<dbset>().HasData(
                new { Column1 = 1, Column2 = "Foo", Column3 = "Bar", CanEdit = false },
            );
