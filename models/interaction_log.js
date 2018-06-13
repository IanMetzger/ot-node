
module.exports = (sequelize, DataTypes) => {
    var interaction_log = sequelize.define('interaction_log', {
        actor_wallet: DataTypes.STRING(50),
        action_type: DataTypes.STRING(100),
        action_time: DataTypes.DATE,
        transaction_hash: DataTypes.STRING(128),
        created_at: DataTypes.INTEGER,
        updated_at: DataTypes.INTEGER,
    }, {
        tableName: 'interaction_log',
        timestamps: true,
    });
    interaction_log.associate = function (models) {
    // associations can be defined here
    };
    return interaction_log;
};
