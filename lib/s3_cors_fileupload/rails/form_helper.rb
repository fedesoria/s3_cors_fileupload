module S3CorsFileupload
  module FormHelper
    # Options:
    # :access_key_id    The AWS Access Key ID of the owner of the bucket.
    #                   Defaults to the `Config.access_key_id` (read from the yaml config file).
    #
    # :acl              One of S3's Canned Access Control Lists, must be one of:
    #                   'private', 'public-read', 'public-read-write', 'authenticated-read'.
    #                   Defaults to `'public-read'`.
    #
    # :max_file_size    The max file size (in bytes) that you wish to allow to be uploaded.
    #                   Defaults to `Config.max_file_size` or, if no value is set on the yaml file `524288000` (500 MB)
    #
    # :bucket           The name of the bucket on S3 you wish for the files to be uploaded to.
    #                   Defaults to `Config.bucket` (read from the yaml config file).
    #
    # :secure           Dictates whether the form action URL will be pointing to a secure URL or not.
    #                   Defaults to `true`.
    #
    # Any other key creates standard HTML options for the form tag.
    def s3_cors_fileupload_form_tag(options = {}, &block)
      policy_helper = PolicyHelper.new(options)
      # initialize the hidden form fields
      hidden_form_fields = {
        :key => '',
        'Content-Type' => '',
        :AWSAccessKeyId => options[:access_key_id] || Config.access_key_id,
        :acl => policy_helper.options[:acl],
        :policy => policy_helper.policy_document,
        :signature => policy_helper.upload_signature,
        :success_action_status => '201'
      }
      # assume that all of the non-documented keys are 
      _html_options = options.reject { |key, val| [:access_key_id, :acl, :max_file_size, :bucket, :secure].include?(key) }
      # return the form html
      construct_form_html(hidden_form_fields, policy_helper.options[:bucket], options[:secure], _html_options,  &block)
    end

    alias_method :s3_cors_fileupload_form, :s3_cors_fileupload_form_tag

    private

    def build_form_options(options = {})
      { :id => 'fileupload' }.merge(options).merge(:multipart => true, :authenticity_token => false)
    end

    # hidden fields argument should be a hash of key value pairs (values may be blank if desired)
    def construct_form_html(hidden_fields, bucket, secure = true, html_options = {}, &block)
      # now build the html for the form
      form_tag(secure == false ? "http://#{bucket}.s3.amazonaws.com" : "https://#{bucket}.s3.amazonaws.com", build_form_options(html_options)) do
        hidden_fields.map do |name, value|
          hidden_field_tag(name, value)
        end.join.html_safe + "
        <!-- The fileupload-buttonbar contains buttons to add/delete files and start/cancel the upload -->  
        <div class='row fileupload-buttonbar'>
          <div class='col-lg-7'>
            <span class='btn btn-success fileinput-button'>
              <i class='fa fa-plus'></i>
              <span>Agregar fotos...</span>
              ".html_safe +
              file_field_tag(:file, :multiple => true) + "
            </span>
            <button type='submit' class='btn btn-primary start'>
              <i class='fa fa-cloud-upload'></i>
              <span>Empezar a subir</span>
            </button>
            <button type='reset' class='btn btn-warning cancel'>
              <i class='fa fa-ban'></i>
              <span>Cancelar</span>
            </button>
            <button type='button' class='btn btn-danger delete'>
              <i class='fa fa-trash-o'></i>
              <span>Borrar</span>
            </button>
            <input type='checkbox' class='toggle'></input>
            <!-- The loading indicator is shown during file processing -->
	          <span class='fileupload-loading'></span>
          </div>
          <!-- The global progress information -->
          <div class='col-lg-5 fileupload-progress fade'>
            <!-- The global progress bar -->
            <div class='progress progress-striped active' role='progressbar' aria-valuemin='0' aria-valuemax='100'>
              <div class='progress-bar progress-bar-success bar' style='width: 0%;'></div>
            </div>
            <!-- The extended global progress information -->
            <div class='progress-extended'>&nbsp;</div>
          </div>
        </div>
        <div class='card'>
          <div class='card-body'>
            <!-- The table listing the files available for upload/download -->
            <table role='presentation' class='table' id='upload_files'>
              <tbody class='files'></tbody>
            </table>
          </div>
        </div>".html_safe + (block ? capture(&block) : '')
      end
    end
  end
end
