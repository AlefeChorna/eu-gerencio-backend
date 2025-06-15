require "pagy/extras/metadata"
require "pagy/extras/overflow"

Pagy::DEFAULT[:items] = 10
Pagy::DEFAULT[:max_items] = 1000
Pagy::DEFAULT[:items_param] = :per_page
Pagy::DEFAULT[:max_per_page] = 1000
# Metadata extra: Provides the pagination metadata in the response
Pagy::DEFAULT[:metadata] = %i[count items page prev next last]
