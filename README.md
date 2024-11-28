Terraform 1-3 sind im zip Datei enthalten Terraform 3 wurde mit workflow auch auf Github raufgeladen wie im aufgabe erwünscht
Github Link:https://github.com/HBK42/Terraformers

Question: Why is Terraform Cloud (or another backend) important when using CI/CD?

Terraform Cloud provides several key features that enhance the infrastructure management process in a CI/CD pipeline.
One important feature is Remote Execution, which allows Terraform operations to be executed on remote infrastructure without needing to run Terraform locally or require access to local resources.
Another crucial feature is State Locking, which ensures that multiple users cannot modify the same Terraform state simultaneously. 
This prevents potential conflicts or data corruption by maintaining the integrity of the infrastructure state.
Terraform Cloud acts as a centralized platform for managing and storing Terraform configurations, 
making it easier for teams to collaborate. It supports version control integration, allowing for seamless management of infrastructure code, 
and it also handles state management efficiently. With these features, Terraform Cloud helps maintain consistency across multiple environments, ensuring that the CI/CD pipeline works reliably and securely.
