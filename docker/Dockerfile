FROM postgres:latest

# Set environment variables for PostgreSQL
ENV POSTGRES_DB=cohort_db
ENV POSTGRES_USER=cohort_user
ENV POSTGRES_PASSWORD=cohort_pass

# Copy initialization script and data file into the container
COPY docker/init.sql /docker-entrypoint-initdb.d/
COPY data/sample_purchase_data.csv /docker-entrypoint-initdb.d/
