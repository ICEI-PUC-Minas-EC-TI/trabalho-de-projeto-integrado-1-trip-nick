-- Tabela de Imagens (deve ser criada primeiro devido às referências)
CREATE TABLE Images (
    image_id INT IDENTITY(1,1) PRIMARY KEY,
    image_name NVARCHAR(255),
    blob_url NVARCHAR(500),
    content_type NVARCHAR(100),
    file_size BIGINT,
    created_date DATETIME2 DEFAULT GETDATE()
);

-- Tabela de Listas
CREATE TABLE List (
    list_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    list_name NVARCHAR(45) NOT NULL,
    is_public BIT NOT NULL -- 1 se a lista for pública e 0 se for privada
);

-- Tabela de Usuários
CREATE TABLE Users (
    user_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    display_name NVARCHAR(55) NOT NULL,
    username NVARCHAR(21) NOT NULL UNIQUE,
    user_email NVARCHAR(35) NOT NULL UNIQUE,
    hash_password NVARCHAR(61) NOT NULL,
    creation_date DATE NOT NULL DEFAULT (CAST(GETDATE() AS DATE)),
    last_update_date DATE NOT NULL DEFAULT (CAST(GETDATE() AS DATE)),
    biography NVARCHAR(450),
    profile_image_id INT,
    FOREIGN KEY (profile_image_id) REFERENCES Images(image_id)
);

-- Tabela de Spots (locais de interesse)
CREATE TABLE Spot (
    spot_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    spot_name NVARCHAR(55) NOT NULL,
    country NVARCHAR(30) NOT NULL,
    city NVARCHAR(35) NOT NULL,
    category NVARCHAR(30) NOT NULL,
    description NVARCHAR(500),
    created_date DATETIME2 DEFAULT GETDATE(),
    spot_image_id INT,
    FOREIGN KEY (spot_image_id) REFERENCES Images(image_id)
    --avg_rating passa a ser um calculo ao inves de um campo    
);

-- Tabela de Associação entre Listas e Spots
CREATE TABLE List_has_Spot (
    list_id INT NOT NULL,
    spot_id INT NOT NULL,
    created_date DATE,
    list_thumbnail_id INT,
    FOREIGN KEY (list_thumbnail_id) REFERENCES Images(image_id),
    FOREIGN KEY (list_id) REFERENCES List(list_id) ON DELETE CASCADE,
    FOREIGN KEY (spot_id) REFERENCES Spot(spot_id) ON DELETE CASCADE
);

-- Tabela de Posts
CREATE TABLE Post (
    post_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    description NVARCHAR(500),
    user_id INT NOT NULL,
    created_date DATE NOT NULL DEFAULT (CAST(GETDATE() AS DATE)),
    type NVARCHAR(11) NOT NULL CHECK (type IN ('community', 'review', 'list')), --Disjunção total, vamos aplicar Herança com chave primária compartilhada
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Community_Post (
    post_id INT PRIMARY KEY NOT NULL,
    title NVARCHAR(45) NOT NULL,
    list_id INT NOT NULL,
    FOREIGN KEY (post_id) REFERENCES Post(post_id) ON DELETE CASCADE,
    FOREIGN KEY (list_id) REFERENCES List(list_id) ON DELETE CASCADE
);

CREATE TABLE Review_Post (
    post_id INT PRIMARY KEY NOT NULL,
    spot_id INT NOT NULL,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    FOREIGN KEY (post_id) REFERENCES Post(post_id) ON DELETE CASCADE,
    FOREIGN KEY (spot_id) REFERENCES Spot(spot_id) ON DELETE CASCADE
);

CREATE TABLE List_Post (
    post_id INT PRIMARY KEY NOT NULL,
    title NVARCHAR(45) NOT NULL,
    list_id INT NOT NULL,
    FOREIGN KEY (post_id) REFERENCES Post(post_id) ON DELETE CASCADE,
    FOREIGN KEY (list_id) REFERENCES List(list_id) ON DELETE CASCADE
);

-- Tabela de Associação entre Post e N Images
CREATE TABLE Post_Images (
    post_id INT NOT NULL,
    image_id INT NOT NULL,
    image_order INT NOT NULL,
    is_thumbnail BIT DEFAULT 0,
    created_date DATETIME2 DEFAULT GETDATE(),
    
    PRIMARY KEY (post_id, image_id),
    
    FOREIGN KEY (post_id) REFERENCES Post(post_id) ON DELETE CASCADE,
    FOREIGN KEY (image_id) REFERENCES Images(image_id) ON DELETE CASCADE
);

-- Filtro que garante apenas uma thumbnail por post
CREATE UNIQUE INDEX IX_Post_Images_Unique_Thumbnail 
ON Post_Images (post_id) 
WHERE is_thumbnail = 1;