module PopInit
    using Random
    export random_pop

    function random_pop(number_genes::Integer, gene_size::Integer)
        return [shuffle(1:gene_size) for _ in 1:number_genes]
    end
end