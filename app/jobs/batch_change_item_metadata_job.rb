class BatchChangeItemMetadataJob < Job

  queue_as :default

  ##
  # @param args [Array] Three-element array with collection UUID at position 0;
  #                     element name at position 1; and array of replacement
  #                     values at position 2.
  # @raises [ArgumentError]
  #
  def perform(*args)
    collection = Collection.find_by_repository_id(args[0])

    element_name = args[1]
    replace_values = args[2]

    if self.task
      self.task.status_text = "Changing \"#{element_name}\" element values "\
        "in #{collection.title}"

      # Indeterminate because the task happens in a transaction from which
      # progress updates won't appear.
      self.task.indeterminate = true
      self.task.save!
    end

    collection.change_item_element_values(element_name, replace_values)

    Solr.instance.commit
    self.task&.succeeded
  end

end
