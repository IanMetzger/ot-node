const MerkleTree = require('./Merkle');
const utilities = require('./Utilities');

/**
 * Import related utilities
 */
class ImportUtilities {
    /**
     * Creates Merkle tree from import data
     * @param vertices  Import vertices
     * @param edges     Import edges
     * @return {Promise<{tree: MerkleTree, leaves: Array, hashPairs: Array}>}
     */
    static async merkleStructure(vertices, edges) {
        const sort = (a, b) => {
            if (a._key < b._key) {
                return -1;
            } else if (a._key > b._key) {
                return 1;
            }
            return 0;
        };
        edges.sort(sort);
        vertices.sort(sort);

        const leaves = [];
        const hashPairs = [];

        // process vertices
        for (const i in vertices) {
            const hash = utilities.sha3(utilities.sortObject({
                identifiers: vertices[i].identifiers,
                data: vertices[i].data,
            }));
            leaves.push(hash);
            hashPairs.push({
                key: vertices[i]._key,
                hash,
            });
        }

        for (const edge of edges) {
            const hash = utilities.sha3(utilities.sortObject({
                identifiers: edge.identifiers,
                _from: edge._from,
                _to: edge._to,
                edge_type: edge.edge_type,
            }));
            leaves.push(hash);
            hashPairs.push({
                key: edge._key,
                hash,
            });
        }

        leaves.sort();
        const tree = new MerkleTree(leaves);
        return {
            tree,
            leaves,
            hashPairs,
        };
    }
}

module.exports = ImportUtilities;