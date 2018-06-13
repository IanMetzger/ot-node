
module.exports = {
    up: (queryInterface, Sequelize) => queryInterface.createTable('data_info', {
        id: {
            allowNull: false,
            autoIncrement: true,
            primaryKey: true,
            type: Sequelize.INTEGER,
        },
        data_id: {
            type: Sequelize.INTEGER,
        },
        total_documents: {
            type: Sequelize.INTEGER,
        },
        total_data_blocks: {
            type: Sequelize.INTEGER,
        },
        root_hash: {
            type: Sequelize.STRING,
        },
        import_timestamp: {
            type: Sequelize.DATE,
        },
        created_at: {
            allowNull: false,
            type: Sequelize.INTEGER,
        },
        updated_at: {
            allowNull: false,
            type: Sequelize.INTEGER,
        },
    }),
    down: (queryInterface, Sequelize) => queryInterface.dropTable('data_infos'),
};
