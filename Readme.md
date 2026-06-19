#EN_US
Structure:
root
└── migration
    └── src
└── src
    └── api
        └── entities
└── 0_migration_checker.sh
└── Cargo.toml

Requirements:

1- Linux operating system and possibly macOS;

2- The 0_migration_checker.sh file must be at the root level and the directory tree must be structured as in the example above.

3- awk must be installed; it is a scripting language for text manipulation.

Info:
If you want to change the directory where the entities are located, modify line 9 of the script:
    ENTITIES_DIR="./src/api/entities" to ENTITIES_DIR="path_to_entities_folder".

Note:
The Sea-orm Migration Simple Checker is a simple shell script to check if your entities have the declared fields present in any Sea-orm-based migration file.
If the entity field has been declared and applied in at least one migration file, it will be considered satisfied.
The script does not manage any type of change history, so it takes into account the current structure of the modeled entity. 

Motivation:

If you typically model entities and then update migration scripts, it's very time-consuming to manually check if any field of any entity has been omitted in a migration.

The Sea-orm CLI can generate entities from the migration file, but it cannot generate the migration file from the modeled entities.

The Sea-orm Migration Simple Checker also does not generate the migration file from the modeled entities; it only checks if all the entity fields have been used and applied across all migration files.


#PT_BR
Estrutura das pastas:
root
└── migration
    └── src
└── src
    └── api
        └── entities
└── 0_migration_checker.sh
└── Cargo.toml

Requerimentos:
1- Sistema operacional linux e talvez macos;

2- arquivo 0_migration_checker.sh deve estar a nível de raiz e a árvore de diretórios deve estar estruturada como no exemplo acima.

3- o awk deve estar intalado, ele é uma linguagem de script para a manipulação de textos.

Info:
    Se você quiser alterar o diretório onde se encontram as entidades, modifique a linha 9 do script:
    ENTITIES_DIR="./src/api/entities" para ENTITIES_DIR="caminho_da_pasta_entities".

Observação:
O Sea-orm Migration Simple Checker é um shellscript simples para verificar se suas entidades tem os campos declarados constantes em algum arquivo de migração baseado no Sea-orm.
Se o campo da entidade foi declarado e aplicado em pelo menos um arquivo de migração ele será considerado como satisfeito.
O script não gerencia nenhum tipo de histórico de alteração, assim ele leva em consideração a estrutura atual da entidade modelada.

Motivação:
Se você costuma modelar as entidades e depois atualizar os scripts de migração, dá muito trabalho verificar manualmente se algum campo de alguma entidade deixou de ser aplicado em alguma migração.
O CLI do Sea-orm consegue gerar as entidades a partir do arquivo de migração, mas não consege gerar o arquivo de migração a partir das entidades modeladas.

O Sea-orm Migration Simple Checker também não gera o arquivo de migração a partir das entidades modeladas, ele apenas faz uma verificação se no conjunto dos arquivos de migração os campos da entidade foram todos aproveitados e aplicados.
