# 8SOAT FIAP Tech Challenge | Grupo 41 | IaC

Este projeto implementa a infraestrutura utilizando **Terraform** como código para gerenciar e provisionar recursos na AWS. A infraestrutura inclui componentes essenciais como **VPC**, **EKS** e **API Gateway**. Além disso, o pipeline de deploy é gerenciado com **GitHub Actions**.

## Infraestrutura como Código (IaC)

A infraestrutura é definida utilizando Terraform e organizada em módulos. Os principais componentes são:

- **VPC**: Uma **Virtual Private Cloud** é criada usando o módulo definido em [modules/aws/vpc](modules/aws/vpc).
- **Subnets**: Subnets públicas e privadas são criadas para propósitos distintos, como bancos de dados (RDS), EKS e acesso à internet. Definido em [modules/aws/subnet](modules/aws/subnet).
- **Internet Gateway**: Permite acesso à internet para recursos na VPC. Definido em [modules/aws/internet_gateway](modules/aws/internet_gateway).
- **NAT Gateway**: Permite que instâncias em subnets privadas acessem a internet. Definido em [modules/aws/nat_gateway](modules/aws/nat_gateway).
- **Route Tables**: Configura tabelas de roteamento associadas às subnets para gerenciar o tráfego. Definido em [modules/aws/route_table](modules/aws/route_table).
- **EKS Cluster**: Um cluster **Amazon EKS** é provisionado para gerenciar aplicações Kubernetes. Definido em [modules/aws/eks_cluster](modules/aws/eks_cluster).
- **Security Groups**: Gerenciam o tráfego de entrada e saída para os recursos. Definido em [modules/aws/security_group](modules/aws/security_group).
- **RDS**: Um banco de dados **Amazon RDS** é provisionado para armazenamento. Definido em [modules/aws/rds](modules/aws/rds).
- **Secrets Manager**: Gerencia informações sensíveis, como credenciais e segredos. Definido em [modules/aws/secrets_manager_secret](modules/aws/secrets_manager_secret).
- **HTTP API Gateway**: Um **API Gateway** é criado para gerenciar APIs HTTP. Definido em [modules/aws/http_api_gateway](modules/aws/http_api_gateway).
- **Cognito User Pool**: Utilizado para autenticação e gerenciamento de usuários.

Os arquivos principais incluem:

- `main.tf`: Define os recursos principais e módulos.
- `variables.tf`: Declara as variáveis usadas nos módulos.
- `providers.tf`: Configura os providers necessários.
- `output.tf`: Exibe as saídas, como o ARN dos recursos provisionados.

## Pipeline de Deploy

O pipeline de deploy é implementado com **GitHub Actions** e está definido em [terraform.yaml](.github/workflows/terraform.yaml). Ele realiza as seguintes etapas:

1. **Checkout**: Faz o checkout do código do repositório.
2. **Configurar Terraform**: Configura o Terraform usando a action `hashicorp/setup-terraform`.
3. **Formatar Terraform**: Verifica e aplica o formato correto ao código Terraform.
4. **Inicializar Terraform**: Inicializa a configuração do Terraform.
5. **Validar Terraform**: Valida os arquivos de configuração.
6. **Planejar Terraform**: Gera um plano com as mudanças que serão aplicadas.
7. **Atualizar Pull Request**: Comenta no pull request com os resultados do `terraform plan`.
8. **Aplicar Terraform**: Aplica as mudanças quando o código é enviado para a branch `main`.

Esse pipeline garante consistência e qualidade na gestão e provisionamento da infraestrutura.

## Executando Localmente

Para testar o Terraform localmente, execute os seguintes comandos:

```sh
# Inicializar Terraform
terraform init

# Validar configuração
terraform validate

# Planejar as mudanças
terraform plan

# Aplicar as mudanças
terraform apply
```

## Estrutura do Projeto

```text
├── .github/
│   └── workflows/
│       └── terraform.yaml        # Pipeline de deploy com GH Actions
├── modules/
│   └── aws/
│       ├── vpc/                  # Módulo VPC
│       ├── subnet/               # Módulo Subnet
│       ├── eks_cluster/          # Módulo EKS
│       ├── rds/                  # Módulo RDS
│       ├── security_group/       # Módulo Security Group
│       └── ...                   # Outros módulos
├── main.tf                       # Configuração principal
├── variables.tf                  # Variáveis globais
├── providers.tf                  # Configuração de provedores
└── output.tf                     # Saídas do Terraform
```
