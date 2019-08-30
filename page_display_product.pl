$versions{'page_display_product.pl'} = '06.6.00.0000';

#######################################################################
#
# AgoraCart and all associated files, except where noted, are
# Copyright 2001 to Present jointly by K-Factor Technologies, Inc.
# and by C E Mayo (aka Mister Ed) at AgoraCart.com & K-Factor.net
#
# This file and related program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# This copyright notice may not be removed or altered in any way.
#
#######################################################################

#
#
# Contains the subroutines/functions for serving product pages by
# category or individually.
#
#

#######################################################################

sub create_html_page_from_db {

    # Check if there is a requested page to be displayed, found in
    # form_data{'page'}.  If there is a form data value for $page, then
    # the display_page subroutine will display that page and exit.
    # If there is no page form value, then the script will generate a
    # dynamic product page using the value ofthe product form variable
    # to query the database.

    if ( ( $page ) && ( $sc_use_html_product_pages ne 'no' ) ) {
        &display_page(
            "$sc_html_product_directory_path/$form_data{'page'}",
            'Display Products for Sale', __FILE__, __LINE__
        );
        call_exit();
    }

    create_html_page_from_db_body();

}

#######################################################################
sub create_html_page_from_db_body {

    local ( $my_output, $status, $prod_message_head, $prod_message_foot ) ;
    local ( @database_rows, @item_ids, @display_fields );
    local ( $total_row_count, $id_index, $display_index, $found, $product_id );
    local ( $row, $field, $empty, $option_tag, $option_location, $output );
    local ( $prod_meta, $my_title_output, $prod_categorymeta, $prod_cat, $prod_name, $titledes)  = q{};
    local ( $meta_category_found, $meta_category_found3, $meta_category_layout_found, $meta_category_loop_shortcircut, $cat_id, $cat_name, $cat_display_name, $cat_lang, $cat_layout, $cat_title, $cat_meta_description, $cat_meta_good, $cat_robotlist, $cat_robot_tags ) = q{};
    local $temp_metatag_key = $form_data{$sc_category_metatag_field};

    # Next the database is querried for rows containing the
    # value of the incoming product variable in the correct
    # category as defined in agora_setup.pl  The script uses
    # the submit_query subroutine in agora_db_lib.pl
    # passing to it a reference to the list array
    # database_rows.
    #
    # submit_query returns a descriptive status message
    # if there was a problem and a total row count
    # for diagnosing if the maximum rows returned
    # variable was exceeded.

    if ( !( $sc_db_lib_was_loaded =~ /yes/i ) ) {
        require_supporting_libraries( __FILE__, __LINE__, "$sc_db_lib_path" );
    }

    ( $status, $total_row_count ) = submit_query(*database_rows);

    # Now that the script has the database rows to be
    # displayed, it will display them.
    #
    # Firstly, the script goes through each database row
    # contained in @database_rows splitting it into it's
    # fields.
    #
    # For the most part, in order to display the database
    # rows, the script will simply need to take each field
    # from the database row and substitute it for a %s in the
    # format string defined in agora_setup.pl
    #
    # However, in the case of options which will modify a
    # product, the script must grab the code from an options
    # file.
    #
    # The special way that options are denoted in the database
    # are by using the format %%OPTION%%option.html in the
    # data file.  This string includes two important bits of
    # information.
    #
    # Firstly, it begins with %%OPTION%%.  This is a flag
    # which will let the script know that it needs to deal
    # with this database field as if it were an option.  When
    # it sees the flag, it will then look to the bit after the
    # flag to see which file it should load. Thus, in this
    # example, the script would load the file option.html for
    # display.
    #
    # Why go through all the trouble?  Well basically, we need
    # to create a system which will handle large chunks of
    # HTML code within the database that are very likely to be
    # similar.

    # sanity check
    if ( ( $form_data{'next'} + $sc_db_max_rows_returned ) < 1 ) {
        $form_data{'next'} = 0;
    }

    $nextCount = $form_data{'next'} + $sc_db_max_rows_returned;
    $prevCount = $form_data{'next'} - $sc_db_max_rows_returned;

    $minCount = $form_data{'next'};
    $maxCount = $form_data{'next'} + $sc_db_max_rows_returned;

    if ( $maxCount < @database_rows ) {
        $my_max_count = $maxCount;
    }
    else {
        $my_max_count = @database_rows;
    }

    $num_returned = @database_rows;
    $nextHits  = $sc_db_max_rows_returned;

    $prod_message_head = product_message( $status, $num_returned, $nextHits );

    if ( ( $form_data{'add_to_cart_button.x'} || $form_data{'add_to_cart_button'} ) && $sc_shall_i_let_client_know_item_added eq 'yes' ) {
        $my_output .= $sc_add_to_cart_success_alert;
    }

    # Mister Ed notes: December 2017
    # Moved from productPage header routine. We want it for ppinc and other data prior to building everything.
    if ( ( ( $form_data{$sc_category_metatag_field} ) || ( $form_data{$sc_catlev2} ) || ( $form_data{$sc_catlev3} ) ) && ( $sc_enable_category_metatag_db eq 'yes' ) ) {

        if ( (-e "$sc_cat_desc_data_path") && !($form_data{'p_id'}) )  {
            open( CATDESCREAD, "$sc_cat_desc_data_path" );
            while ( ($line = <CATDESCREAD>) && ( $meta_category_found3 eq '' ) && ( $meta_category_loop_shortcircut eq '' ) ) {
                chomp $line;
                my ($name,$displayname,$lang,$layout,$break_cat_layout_lock,$description,$robotlist, $robot_tags) = split(/\|/,$line);
                if ( ( $name eq $temp_metatag_key ) && ( $meta_category_found eq '' ) && ( $meta_category_found3 eq '' ) ) {
                    $meta_category_found = 1;
                    $cat_name = $name;
                    if ( $displayname ) {
                        $cat_display_name = $displayname;
                    }
                    else {
                        $cat_display_name = $name;
                    }
                    $cat_robotlist = $robotlist;
                    $cat_robot_tags = $robot_tags;
                    if ( $layout ) {
                      if (
                        ( ( $break_cat_layout_lock eq 'yes' ) && ( ( $form_data{$sc_catlev2} eq '' ) && ( $form_data{$sc_catlev3} eq '' ) ) )
                        || ( $break_cat_layout_lock ne 'yes' )
                      ) {
                        $cat_layout = $layout;
                        $meta_category_layout_found = 1;
                      }
                    }
                    chomp($description);
                    $cat_meta_description = $description;
                    $cat_meta_good = 'yes';
                }
                if ( ( $form_data{$sc_catlev2} ) && ( $name eq $form_data{$sc_catlev2} ) && ( $meta_category_found3 eq '' ) ) {
                    $meta_category_found = 1;
                    $cat_name = $name;
                    if ( $displayname ) {
                        $cat_display_name = $displayname;
                    }
                    else {
                        $cat_display_name = $name;
                    }
                    $cat_robotlist = $robotlist;
                    $cat_robot_tags = $robot_tags;
                    if ($layout) {
                      $cat_layout = $layout;
                      $meta_category_layout_found = 1;
                    }
                    chomp($description);
                    $cat_meta_description = $description;
                    $cat_meta_good = 'yes';
                }
                if ( ( $form_data{$sc_catlev3} ) && ( $name eq $form_data{$sc_catlev3} ) ) {
                    $meta_category_found = 1;
                    $meta_category_found3 = 1;
                    $cat_name = $name;
                    if ( $displayname ) {
                        $cat_display_name = $displayname;
                    }
                    else {
                        $cat_display_name = $name;
                    }
                    $cat_robotlist = $robotlist;
                    $cat_robot_tags = $robot_tags;
                    if ($layout) {
                      $cat_layout = $layout;
                      $meta_category_layout_found = 1;
                    }
                    chomp($description);
                    $cat_meta_description = $description;
                    $cat_meta_good = 'yes';
                }
                if ( ( $form_data{$sc_catlev2} eq '' ) && ( $form_data{$sc_catlev3} eq '' )  && ( $meta_category_found ) ) {
                    $meta_category_loop_shortcircut = 1;
                }


             }
             close(CATDESCREAD);
        }
    }

    $last_product_displayed = 'no';

    foreach $row (@database_rows) {
        $rowCount++;
        $prevHits = $sc_db_max_rows_returned;
        $nextHits = $sc_db_max_rows_returned;

        if ( $rowCount > $minCount && $rowCount <= $maxCount ) {

            $product_id = $row;
            $found = check_db_with_product_id( $product_id, *database_fields );

            codehook( 'create_html_page_read_db_item' );

            # SEO Stuff
            $prod_cat = $database_fields[1]; # product (aka product category)
            $prod_name = $database_fields[3]; # product name, for single product use
            $titledes = $database_fields[$sc_seo_index]; #Allow manager setting for which to pass, for single product use
            my $premeta = $database_fields[5]; # product description
            $premeta =~ s/<.*>/ /g; #strip html tags
            $premeta =~ s/\[\[.*\]\]/ /g; #strip AgoraCart tokens
            $premeta =~ s/\'//g; #strip single quotes
            $premeta =~ s/\"//g; #strip double quotes
            $premeta =~ s/\$//g;
            $premeta =~ s/\n//g;
            $premeta =~ s/\|//g;
            my @description = split(/\./,$premeta);
            # uses first two sentences of description ( the 2 text strings before the first two period characters)
            $prod_meta = $description[0] . ". " . $description[1] ; # for single product use
            $prod_categorymeta .= $prod_name . ','; # list of product names, in case no category master metadata exists

            foreach $field (@database_fields) {

                # if field starts with [[IMG]] then it is an image,
                # and we will generate an HTML IMG tag for it
                if ( $field =~ /^\[\[IMG\]\]/i ) {
                    ( $image_tag, $image_location ) = split( /\]\]/, $field, 2 );
                    $field =
                        '<img src="'
                      . "$URL_of_images_directory/$image_location"
                      . '" alt="'
                      . "$image_location" . '">';
                } elsif ( $field =~ /^%%IMG%%/i ) {
                    ( $empty, $image_tag, $image_location ) = split ( /%%/, $field );
                    $field = '<img src="'
                    . "$URL_of_images_directory/$image_location"
                    . '" alt="' . "$image_location" . '">';
                }

                # For every field in every database row, the script simply
                # checks to see if it begins (^) with %%OPTION%%.  If so,
                # it splits out the string into three strings, one
                # empty, one equal to OPTION and one equal to the location
                # of the option to be used.  Then the script resets the
                # field to null because it is about to overwrite it.

                if ( $field =~ /^%%OPTION/i ) {
                    ( $empty,$option_tag, $option_location, $junk ) = split( /%%/, $field, 4 );
                    $field = q{};

                    # The option file is then opened and read.  Next, every
                    # line of the option file is appended to the $field
                    # variable and the file is closed again.  Then the
                    # current product id number is substituted for the
                    # [[PRODUCT_ID]] flag in the option_prep subroutine and
                    # and any optpre and optpost agorascript is run

                    $field = load_opt_file($option_location);
                    $field = option_prep( $field, $option_location, $product_id );

                }

                # Now see if we need to load a generic file of some type
                if ( $field =~ /^\[\[FILE\]\]/i ) {
                    ( $option_tag, $option_location ) = split( /\]\]/, $field );
                    ( $empty, $option_tag ) = split( /\[\[/, $field );
                    $field = '';
                    {
                        open( OPTION_FILE, "<$sc_generic_directory_path/$option_location" );
                        local $/ = undef;
                        $field = <OPTION_FILE>;
                        close(OPTION_FILE);
                    }
                    $field = agorascript( $field, 'pre', "$option_location", __FILE__,__LINE__ );

                    # normal operation - v5.9 and above
                    $field =~ s/\[\[PRODUCT_ID\]\]/$database_fields[$sc_db_index_of_product_id]/ig;
                    $field =~ s/\[\[PRODUCTID\]\]/$database_fields[$sc_db_index_of_product_id]/ig;
                    $field =~ s/\[\[URLofImages\]\]/$URL_of_images_directory/g;
                    $field =~ s/\[\[cart_id\]\]/$cart_id/g;

                    $field = agorascript( $field, 'post', "$option_location", __FILE__, __LINE__ );

                    ( $very_first_part, $field, $junk ) =
                      split( /<h3>--cut here--<\/h3>/i, $field, 3 );
                    if ( $field eq '' ) {
                        $field = $very_first_part;
                    }
                    if ( $field eq '' ) {
                        $field = "(file $option_location not found)";
                    }
                }

            } # End of foreach $field (@sc_db_userfield_and_options_index)

            if ( $rowCount == ( 1 + $minCount ) ) {
                $first_product_displayed = 'yes';
            }
            else {
                $first_product_displayed = 'no';
                if ( $rowCount == $maxCount ) {
                    $last_product_displayed = 'yes';
                }
            }

            $sc_used_ppinc_category = q{};
            create_display_fields(@database_fields);

            $my_output .= prep_displayProductPage(&get_sc_ppinc_info);

        } # if ( $rowCount > $minCount && $rowCount <= $maxCount )

    }# End of foreach $row (@database_rows)

    # Product Page Title Box
    my $temp_prod_title = '';
    my $temp_prod_title_set_by = '';

    $my_title_output = $sc_product_page_h1_title_begin_tag;
    if ( $form_data{'product'} ) {
        $temp_prod_title = $form_data{'product'};
        $temp_prod_title =~ s/\-/ /g;
        $temp_prod_title =~ s/\_/\-/g;
        $temp_prod_title_set_by = 'formProduct';

    }
    elsif ( $form_data{'searchProdHeader'} ) {
        $temp_prod_title = $form_data{'searchProdHeader'};
        $temp_prod_title =~ s/\-/ /g;
        $temp_prod_title =~ s/\_/\-/g;
        $temp_prod_title_set_by = 'searchProdHeader';
    }

    if ( $meta_category_found && $cat_display_name ) {
        $temp_prod_title = $cat_display_name;
        $temp_prod_title_set_by = 'prodMetaDB';
    }

    $my_title_output .= $temp_prod_title;

    if ( $form_data{$sc_catlev2} && $sc_catlev2 ) {
        my $temp = $form_data{$sc_catlev2};
        $temp =~ s/\-/ /g;
        $temp =~ s/grthan/-/g;
        $temp =~ s/\_/ /g;
        $my_title_output .= $sc_product_page_h1_title_cat_separator . $temp;
    }
    if ( $form_data{$sc_catlev3} && $sc_catlev3 ) {
      my $temp = $form_data{$sc_catlev3};
      $temp =~ s/\-/ /g;
      $temp =~ s/grthan/-/g;
      $temp =~ s/\_/ /g;
      $my_title_output .= $sc_product_page_h1_title_cat_separator . $temp;
    }

    # override for keywords
    if ( ( $form_data{'keywords'} ) && !( $meta_category_found ) ) {
        $my_title_output = qq|$sc_product_page_h1_title_begin_tag_smaller $sc_keyword_results_title $form_data{'keywords'}|;
        $temp_prod_title_set_by = 'formKeywords';
    }
    if ( $sc_use_alt_next_display =~ /yes/i ) {
        $prod_message_head = q{};
    }
    $prod_message_foot = $prod_message_head;

    $my_title_output .= $sc_product_page_h1_title_end_tag;

    if ( $temp_prod_title_set_by eq 'formProduct'  && $sc_skip_form_supplied_productname_ppinc_titles =~ /yes/i ) {
        $my_title_output = $sc_skipped_ppinc_title_box;
    }

    codehook('create_html_page_from_db_hook');

    $my_output = $my_title_output . $prod_message_head . $my_output;

    $prod_message_head = q{}; # blank out for legacy passing below

    if ( $cat_meta_description ) {
        $cat_meta_description .= ' ' . $prod_categorymeta;
        if ( length($cat_meta_description) > 155 ) {
            $cat_meta_description  = substr( $cat_meta_description, 0, 155 );
        }
        $prod_categorymeta = $cat_meta_description;
    }
    else {
        if ( length($prod_categorymeta) > 155 ) {
            $prod_categorymeta  = substr( $prod_categorymeta, 0, 155 );
        }
    }


    # to prevent massive text strings if using sentences from products for category metatags.
    if ( length($prod_meta) > 155 ) {
        $prod_meta  = substr( $prod_meta, 0, 155 );
    }
    if ( $sc_header_printed ne 1 ) {
        &print_agora_http_headers();
    }
    if ( $sc_test_data_to_print && $sc_print_test_data eq 'yes' ) {
        print $sc_test_data_to_print;
    }

    if ( $meta_category_found == 1 ) {
        product_page_header( $sc_product_display_title,$prod_message_head,$cat_meta_description,$prod_cat,$titledes,$prod_cat,$prod_categorymeta,$cat_robot_tags);
    }
    else {
        product_page_header( $sc_product_display_title,$prod_message_head,$prod_meta,$prod_name,$titledes,$prod_cat,$prod_categorymeta,$cat_robot_tags );
    }

    print $my_output;
    product_page_footer($prod_message_foot);
    if ( $sc_ask_for_return ne 1 ) {
        call_exit();
    }

}

#######################################################################
#                    product_page_header Subroutine                   #
#######################################################################
# product_page_header is used to display the shared
# HTML header used for database-based product pages.  It
# takes one argument, $page_title, which will be used to
# fill the data between the <TITLE> and </TITLE>.
# Typically, this value is determined by
# $sc_product_display_title in agora_messages.pl.
#
# The subroutine is called with the following syntax:
#
# product_page_header("Desired Title");
#
# SEO friendly / Canonical URLs originally submitted by
# Rachel Smisek (aka Salta4)
#
# metatag key catching for description metatags added by Mister Ed - March 15, 2012
#
# Uses the following local variables create_html_page_from_db_body:
# c $meta_category_found, $meta_category_found3

sub product_page_header {

    # if a category, $name and $category will be same value.
    local ( $page_title, $prod_message, $meta_in, $name, $titledes, $category, $categorymeta, $cat_robot_tags ) = @_;

    # Then, it assigns the text of all of the hidden fields
    # that may need to be passed as state information to
    # $hidden_fields using the make_hidden_fields subroutine
    # which will be discussed later.

    local ( $hidden_fields ) = make_hidden_fields();
    local ( $my_hdr, $canonical_url );
    local ( $canon, $meta, $metaSite, $title, $good ) = q{};
    local ( $temp_robot_tags ) = $sc_robot_meta_tags;
    my ( $temp_header_tag_key, $line, $pagination ) = q{};

   $title = $page_title . $name;

   if ( $form_data{$sc_catlev2} ) {
       $temp = $form_data{$sc_catlev2};
       $temp =~ s/-grthan-/ - /g;
       $title .= ' ' . $temp;
   }
   if ( $form_data{$sc_catlev3} ) {
       $temp = $form_data{$sc_catlev3};
       $temp =~ s/-grthan-/ - /g;
       $title .= ' ' . $temp;
   }
   if ( $form_data{$sc_catlev4} ) {
       $temp = $form_data{$sc_catlev4};
       $temp =~ s/-grthan-/ - /g;
       $title .= ' ' . $temp;
   }

   $meta = $meta_in;
   $metaSite = $categorymeta;

   if ( $mytitlenumber ){
       $pagination = ' - page ' . $mytitlenumber;
       $title .= $pagination;
   }

   # individual product page - single product
   if ( ( $form_data{'p_id'} ) && ( $sc_seo_friendly =~ /yes/i ) ) {
       $pagination = q{};

       $sc_pid_title =~ s/\[\[name\]\]/$linkname/ig;
       $sc_pid_title =~ s/\[\[userfield\]\]/$titledes/ig;
       $sc_pid_title =~ s/\[\[category\]\]/$catdes/ig;
       $sc_pid_title =~ s/\[\[subcategory\]\]//ig;
       $sc_pid_title =~ s/\[\[pid\]\]/$form_data{'p_id'}/ig;
       $title = $sc_pid_title . $pagination;
       $meta = $name . ' - ' . $meta_in;
       if ( $metaSite eq '' ) {
           $metaSite = $sc_generic_productpage_meta_description;
       }
   }
   elsif ( ( $meta_category_found  eq '' ) && ( $sc_seo_friendly =~ /yes/i ) )  { # parse category title option set in SEO manager
       $sc_cat_title =~ s/\[\[user2\]\]/$form_data{'user2'}/ig;
       $sc_cat_title =~ s/\[\[user3\]\]/$form_data{'user3'}/ig;
       $sc_cat_title =~ s/\[\[user4\]\]/$form_data{'user4'}/ig;
       $sc_cat_title =~ s/\[\[user5\]\]/$form_data{'user5'}/ig;
       if ( $sc_userfields_available =~ /10|20/ ) {
            $sc_cat_title =~ s/\[\[user6\]\]/$form_data{'user6'}/ig;
            $sc_cat_title =~ s/\[\[user7\]\]/$form_data{'user7'}/ig;
            $sc_cat_title =~ s/\[\[user8\]\]/$form_data{'user8'}/ig;
            $sc_cat_title =~ s/\[\[user9\]\]/$form_data{'user9'}/ig;
            $sc_cat_title =~ s/\[\[user10\]\]/$form_data{'user10'}/ig;
        }
        if ( $sc_userfields_available eq '20' ) {
           $sc_cat_title =~ s/\[\[user11\]\]/$form_data{'user11'}/ig;
           $sc_cat_title =~ s/\[\[user12\]\]/$form_data{'user12'}/ig;
           $sc_cat_title =~ s/\[\[user13\]\]/$form_data{'user13'}/ig;
           $sc_cat_title =~ s/\[\[user14\]\]/$form_data{'user14'}/ig;
           $sc_cat_title =~ s/\[\[user15\]\]/$form_data{'user15'}/ig;
           $sc_cat_title =~ s/\[\[user16\]\]/$form_data{'user16'}/ig;
           $sc_cat_title =~ s/\[\[user17\]\]/$form_data{'user17'}/ig;
           $sc_cat_title =~ s/\[\[user18\]\]/$form_data{'user18'}/ig;
           $sc_cat_title =~ s/\[\[user19\]\]/$form_data{'user19'}/ig;
           $sc_cat_title =~ s/\[\[user20\]\]/$form_data{'user20'}/ig;
       }
       $sc_cat_title =~ s/\[\[category\]\]/$form_data{'product'}/ig;
       $title = $sc_cat_title . $pagination;

       codehook('category_page_metatags');
   }

   codehook('pre_canonical_link_build');

   if ($sc_seo_friendly !~ /yes/ix){
       $good = 'yes';

       #build our canonical link - product, user2, user3, user4, user5, next
       if (
          ( ( $form_data{'product'} ) && ( $form_data{'p_id'} eq '' ) )
          || ( ( $form_data{'hdr'} ) && ( $form_data{'p_id'} eq '' ) && ( $sc_enable_category_metatag_db =~ /yes/ ) )
          || ( ( $sc_enable_category_metatag_db =~ /yes/ ) && ( $form_data{'product'} eq '' ) && ( $form_data{'p_id'} eq '' )  )
          )  {
           $canon .= "product\=$form_data{'productURL'}";
           if ( $form_data{'user2'} ) { $canon .= "\&user2\=$form_data{'user2'}";}
           if ( $form_data{'user3'} ) { $canon .= "\&user3\=$form_data{'user3'}"; }
           if ( $form_data{'user4'} ) { $canon .= "\&user4\=$form_data{'user4'}"; }
           if ( $form_data{'user5'} ) { $canon .= "\&user5\=$form_data{'user5'}"; }
           if ( $sc_userfields_available =~ /10|20/ ) {
               if ( $form_data{'user6'} ) { $canon .= "\&user6\=$form_data{'user6'}"; }
               if ( $form_data{'user7'} ) { $canon .= "\&user7\=$form_data{'user7'}"; }
               if ( $form_data{'user8'} ) { $canon .= "\&user8\=$form_data{'user8'}"; }
               if ( $form_data{'user9'} ) { $canon .= "\&user9\=$form_data{'user9'}"; }
               if ( $form_data{'user10'} ) { $canon .= "\&user10\=$form_data{'user10'}"; }
           }
           if ( $sc_userfields_available eq '20' ) {
               if ( $form_data{'user11'} ) { $canon .= "\&user11\=$form_data{'user11'}"; }
               if ( $form_data{'user12'} ) { $canon .= "\&user12\=$form_data{'user12'}"; }
               if ( $form_data{'user13'} ) { $canon .= "\&user13\=$form_data{'user13'}"; }
               if ( $form_data{'user14'} ) { $canon .= "\&user14\=$form_data{'user14'}"; }
               if ( $form_data{'user15'} ) { $canon .= "\&user15\=$form_data{'user15'}"; }
               if ( $form_data{'user16'} ) { $canon .= "\&user16\=$form_data{'user16'}"; }
               if ( $form_data{'user17'} ) { $canon .= "\&user17\=$form_data{'user17'}"; }
               if ( $form_data{'user18'} ) { $canon .= "\&user18\=$form_data{'user18'}"; }
               if ( $form_data{'user19'} ) { $canon .= "\&user19\=$form_data{'user19'}"; }
               if ( $form_data{'user20'} ) { $canon .= "\&user20\=$form_data{'user20'}"; }
           }
           if ( $form_data{'hdr'} ) { $canon .= "\&hdr\=$form_data{'hdr'}"; }
           if ( ( $form_data{'next'} ) && ( $form_data{'next'} ne '0' ) ) { $canon .= "\&next\=$form_data{'next'}"; }

           codehook('category_page_canonical');

       }
       elsif ( $form_data{'p_id'} ) {
           $canon .= "p_id\=$form_data{'p_id'}";
           if ($form_data{'ppinc'} ) {
               $canon .= "\&ppinc\=$form_data{'ppinc'}";  #think about this. want to be able to specify seo ppinc?
           }
           $canon .= "\&name\=$linkname";
           codehook('product_page_canonical');
       }
       else {
           if ( $meta_category_found eq '' ) {
               $good = 'no';
           }
       }

       if ($form_data{'xm'}) {
           $canon .= '&xm=' . $form_data{'xm'};
       }

       $canon =~ s/\&/\&amp;/g; #for valid html
       $canonical_url = qq~$sc_store_url?$canon~;

       if ($good eq 'no' ) {
           $sc_special_page_meta_tags .= $sc_noindex_robot_meta_tags;
       }

       codehook('canon_url');

   }
   else{ #we are using seo friendly mod-rewrite urls
       my $requri = q{};
       my $dir = $sc_store_url;
       $dir =~ /http:.+\.\w{3}\/(.+)\/agora\.cgi/i;
       $dir = $1;
       if ( $ENV{'QUERY_STRING'} =~ /dc|order_form/i ) {
           $sc_special_page_meta_tags .= $sc_noindex_robot_meta_tags;

           codehook('bot_instructions_non_redirected');

       }
       else {
           $requri = $ENV{'REQUEST_URI'};
           $canonical_url = $ENV{'HTTP_HOST'} . $requri;
           $canonical_url =~ s/-n0//g;
       }

        codehook('canonical_url_redirected');

    }

    if ( $cat_robot_tags ) {
        $temp_robot_tags = $cat_robot_tags;
    }

    $my_hdr = $sc_html_framework{'Product Header'};
    $my_hdr =~ s/\[\[canonicalURL\]\]/$canonical_url/gi;
    $my_hdr =~ s/\[\[metaDescription\]\]/$meta/gi;
    $my_hdr =~ s/\[\[metaSiteDescription\]\]/$metaSite/gi;
    $my_hdr =~ s/\[\[site_name\]\]/$sc_schema_site_name/gi;
    $my_hdr =~ s/\[\[title\]\]/$title/gi;
    $my_hdr =~ s/\[\[head_info\]\]/$sc_standard_head_info/i;
    $my_hdr =~ s/\[\[head_charset\]\]/$sc_header_charset/i;
    $my_hdr  =~ s/\[\[robots_meta\]\]/$temp_robot_tags/ig;
    $my_hdr =~ s/\[\[doc_type\]\]/$sc_doctype/i;
    $my_hdr =~ s/\[\[special_meta_tags\]\]/$sc_special_page_meta_tags/i;
    $my_hdr =~ s/\[\[image_og\]\]//i;
    $my_hdr = agorascript( $my_hdr, '', 'sub product_page_header', __FILE, __LINE__ );

    codehook('product_page_header');

    print $my_hdr;

    StoreHeader();

    if ( $prod_message ) {
        print "$prod_message\n";
    }

}
#######################################################################
#                    product_page_footer Subroutine                   #
#######################################################################
# product_page_footer is used to generate the HTML page
# footer for database-based product pages.  It takes two
# arguments, $db_status and $total_rows_returned and is
# called with the following syntax:
#
# product_page_footer($status,$total_row_count);

sub product_page_footer {

    local $keywords = $form_data{'keywords'};
    $keywords =~ s/ /+/g;

    # $db_status gives us the status returned from the database
    # search engine and $total_rows_returned gives us the
    # actual number of rows returned.  $warn_message which
    # is first initialized, will be used to generate a warning
    # that the user should narrow their search in case
    # too many rows were returned.
    local ($prod_message) = @_;
    local $zmessage = qq~$prod_message~;
    #$sc_product_display_footer removed from above

    codehook('product_page_footer_top');

    print $zmessage;

    codehook('product_page_footer_bot');

    StoreFooter();

}

#######################################################################
#                    product_message Subroutine                   #
#######################################################################
# edited / changed  by Mister Ed of AgoraCart.com - August 2010
# changed to include code contributions & requests for
# improved handling of search page listings (by numbers)
# now looks like the following example when displayed:
# Found 26 items, showing 15 to 20.  << First  < Previous  3 4 5 6 7 8 9 10 11 12 13   Next > Last >>
#
# code snippets donated by
# Rachel Smisek (aka Salta4)

sub product_message {

    local ( $db_status, $rowCount, $nextHits ) = @_;
    local ($warn_message);
    local ($prevHits) = $nextHits;
    local $keywords  = $form_data{'keywords'};
    local $save_next = $form_data{'next'};     # we change this value here temporarily
    my ($super_indexer) = qq{$sc_add_on_modules_dir/page_indexer.pl};

    $keywords =~ s/ /+/g;

     if ( $sc_number_of_pages_each_Side eq '') {
         $sc_number_of_pages_each_Side = 5;
     }

    # $db_status gives us the status returned from the database
    # search engine and $total_rows_returned gives us the
    # actual number of rows returned.  $warn_message which
    # is first initialized, will be used to generate a warning
    # that the user should narrow their search in case
    # too many rows were returned.

    # If the database returned a status, the script checks to
    # see if it was like the string "max.*row.*exceed".  If
    # so, it lets the user know that they need to narrow their
    # search.
    if ( $db_status ) {
    if ( -e $super_indexer ) {
        $warn_message = super_indexer($db_status, $rowCount, $nextHits, $href_info);
    }
    else {

        if ( $db_status =~ /max.*row.*exceed.*/i ) {
            $warn_message = qq~<div class="ac_seach_results">\n~;

            if ( $maxCount < $rowCount ) {
                $my_last = $maxCount;
            }
            else {
                $my_last = $rowCount;
            }
            if ( $minCount < 0 ) {
                $my_first = 1;
            }
            else {
                $my_first = $minCount + 1;
            }
            if ( $minCount < $nextHits ) {
                $my_prevHits = $maxCount - $nextHits;
            }
            else {
                $my_prevHits = $prevHits;
            }

            $sc_found01 =~ s/\[\[rowCount\]\]/$rowCount/;

            if ( $my_first == $my_last ) {
                $warn_message .= "$sc_found01 " . $my_last . $sc_found_spacing01;
            }
            else {
                $warn_message .=
                    "$sc_found01 "
                  . ($my_first)
                  . " $sc_foundto "
                  . $my_last
                  . $sc_found_spacing02;
            }

            my $znext = $form_data{'next'};
            my $zsanity_pagechk = ( $rowCount % $nextHits );
            if ( $zsanity_pagechk != 0 ) {
                $total_pages = ( $rowCount - ( $rowCount % $nextHits ) ) / $nextHits+1;
            }
            else {
                $total_pages = ( $rowCount - ($rowCount % $nextHits ) ) / $nextHits;
            }

            # page on? previous hits / next hits - if showing 61-70 of 100, 60/100 = 6+1=7 I am on pg 7
            my $mynumber = int( ( $prevCount ) / $nextHits ) + 1;
            $mytitlenumber = $mynumber + 1;
            my $startFrom = $mynumber - $sc_number_of_pages_each_Side;

            if ( $startFrom < 0 ) {
                $startFrom = 0;
            }

            my $endOn = $mynumber + $sc_number_of_pages_each_Side + 1;

            if ( $endOn > $total_pages ) {
                $endOn = $total_pages;
            }

            if ( $startFrom >= 1 ) {
                $form_data{'next'} = 0;
                if (  $sc_seo_friendly =~ /yes/i ) {
                    $href_fields = make_href_fields(yes);
                    $href_info = $sc_store_base_URL . $href_fields;
                }
                else {
                    $href_fields = make_href_fields();
                    $href_info = "$sc_main_script_url?$href_fields";
                }
                $warn_message .= qq!<a href=$href_info>$sc_found04</a>!;
            }

            if ( $znext > '0') {
                $form_data{'next'} = $prevCount;
                if (  $sc_seo_friendly =~ /yes/i ) {
                    $href_fields = make_href_fields(yes);
                    $href_info = $sc_store_base_URL . $href_fields;
                }
                else {
                    $href_fields = make_href_fields();
                    $href_info = "$sc_main_script_url?$href_fields";
                }
                $warn_message .= qq!$sc_found_spacing03<a class="next_matches" href="$href_info">$sc_found02</a>$sc_found_spacing03!;
            }

            for ( $i = $startFrom; $i < $endOn; $i++) {
                $numberthis=$i+1;
                $form_data{'next'} = ( $numberthis - 1 ) * $nextHits;
                if (  $sc_seo_friendly =~ /yes/i ) {
                    $href_fields = make_href_fields(yes);
                    $href_info = $sc_store_base_URL . $href_fields;
                }
                else {
                    $href_fields = make_href_fields();
                    $href_info = "$sc_main_script_url?$href_fields";
                }
                if ( $i != $mynumber ) {
                    $warn_message .= qq!<a class="next_matches" href="$href_info">!;
                }
                $warn_message .= $numberthis;
                if ( $i != $mynumber ) {
                    $warn_message .= '</a>';
                }
                $warn_message .= $sc_page_number_spacing01;
            }

            $form_data{'next'} = $maxCount;

            if ( $maxCount < $rowCount ) {
                if (  $sc_seo_friendly =~ /yes/i ) {
                    $href_fields = make_href_fields(yes);
                    $href_info = $sc_store_base_URL . $href_fields;
                }
                else {
                    $href_fields = make_href_fields();
                    $href_info = "$sc_main_script_url?$href_fields";
                }
                $warn_message .= qq!$sc_found_spacing03<a class="next_matches" href="$href_info">$sc_found03</a>!;
            }

            if ( $total_pages - $endOn >= 1 ) {
                $form_data{'next'} = ( $total_pages - 1 ) * $nextHits;
                if (  $sc_seo_friendly =~ /yes/i ) {
                    $href_fields = make_href_fields(yes);
                    $href_info = $sc_store_base_URL . $href_fields;
                }
                else {
                    $href_fields = make_href_fields();
                    $href_info = "$sc_main_script_url?$href_fields";
                }
                $warn_message .= qq!$sc_found_spacing03<a class="next_matches" href="$href_info">$sc_found05</a>!;
            }

            $warn_message.="<br>";
            $warn_message .= "</span>\n";
            $warn_message .= "</div></center>";

        }

    }
    }

    # Then the script displays the footer information defined
    # with $sc_product_display_footer in agora_html.inc and
    # adds the final basic HTML footer.  Notice that one of the
    # submit buttons, "Return to Frontpage" is isolated into
    # the $sc_no_frames_button variable.  This is because in
    # the frames version, we do not want that option as it
    # will cause an endlessly fracturing frame system.  Thus,
    # in a frame store, you would simply set
    # $sc_no_frames_button to "" and nothing would print here.
    # Otherwise, you may include that button in your footer
    # for ease of navigation.  The variable itself is defined
    # in agora_setup.pl.  The script also will print the
    # warning message if there is a value for it.

    $form_data{'next'} = $save_next;    # must restore our original state!
    return $warn_message;

}

#######################################################################
#                  create_display_fields Subroutine
#######################################################################
# fixed dynamic .inc files by category
# by Mister Ed (K-Factor Technologies, Inc) 10/16/2003

sub create_display_fields {
    local (@database_fields) = @_;
    local ( $id_index, $display_index, $category );
    my ($continue) = 'yes';

    codehook('create_display_fields_top');

    if ( $continue ne 'yes' ) { return; }

    # create @display_fields, @item_ids, $itemID variables

    # First, however, we must format the fields correctly.
    # Initially, @display_fields is created which contains the
    # values of every field to be displayed, including a
    # formatted price field.

    @display_fields = ();
    my @temp_fields    = @database_fields;
    foreach my $display_index (@sc_db_index_for_display)   {
        if ( $display_index == $sc_db_index_of_price )  {
            $temp_fields[$sc_db_index_of_price] = display_price( $temp_fields[$sc_db_index_of_price] );
        }

        push( @display_fields, $temp_fields[$display_index] );
    }

# Then, the elements of the NAME field are created so that
# customers will be able to specify an item to purchase.
# We are careful to substitute double quote marks ("), and
# greater and less than signs (>,<) for the tags ~qq~,
# ~gt~, and ~lt~. The reason that this must be done is so
# that any double quote, greater than, or less than
# characters used in URL strings can be stuffed safely
# into the cart and passed as part of the NAME argument in
# the "add item" form.  Consider the following item name
# which must include an image tag.
#
# <INPUT TYPE = "text"
#        NAME = "item-0010|Vowels|15.98|The letter A|~lt~IMG SRC = ~qq~Html/Images/a.jpg~qq~ ALIGN = ~qq~left~qq~~gt~"
#
# Notice that the URL must be edited. If it were not, how
# would the browser understand how to interpret the form
# tag?  The form tag uses the double quote, greater
# than, and less than characters in its own processing.
    @item_ids = ();

    foreach my $id_index (@sc_db_index_for_defining_item_id) {
        $database_fields[$id_index] =~ s/\"/~qq~/g;
        $database_fields[$id_index] =~ s/\>/~gt~/g;
        $database_fields[$id_index] =~ s/\</~lt~/g;

        push( @item_ids, $database_fields[$id_index] );

    }

    $itemID = join( "\|", @item_ids );

    # dynamic ppinc layouts by category name
    if ( $sc_use_category_name_as_ppinc_root =~ /yes/i
        && $form_data{'ppinc'} ne 'search'
        && $form_data{'ppinc'} ne 'search2'
        && $form_data{'ppinc'} eq ''
         # $meta_category_layout_found ($meta_category_found) set in create_html_page_from_db
        && $meta_category_layout_found eq '' )
    {
        my $myproduct = $database_fields[ $db{'product'} ];
        $myproduct =~ s/ /\_/g;
        if ( -f "$sc_product_layouts_dir/$myproduct.inc" ) {
            $ppinc_root_name = $myproduct;
            $sc_used_ppinc_category = 1;
        }
    }

    codehook('create_display_fields_bot');
}

#######################################################################

sub itemID {
    # used to allow an alternate %%itemID%% string using a token
    # like [[itemID-a]] in a productPage.inc file
    my ($my_modifier) = @_;
    my (@stuff)       = @item_ids;
    if ( $my_modifier ) {
        @stuff[0] .= $sc_web_pid_sep_char . $my_modifier;
    }
    return 'item-' . join( "\|", @stuff );
}

#######################################################################

sub prodID {
    # used to allow an alternate %%ProductID%% string using a
    # token like [[prodID-a]] in a productPage.inc file
    my ($my_modifier) = @_;
    my (@stuff)       = @item_ids;
    if ( $my_modifier ) {
        @stuff[0] .= $sc_web_pid_sep_char . $my_modifier;
    }
    return $stuff[0];
}

#######################################################################

sub QtyBox {
    # allow an alternate %%QtyBox%% string using a token
    # like %%QtyBox-a,1%% in a productPage.inc file
    my ( $my_modifier, $qty ) = @_;
    my ($my_box)     = $qty_box_html;
    my ($my_pid)     = prodID($my_modifier);
    my ($my_item_id) = itemID($my_modifier);
    $my_box =~ s/%%itemID%%/$my_item_id/ig;
    $my_box =~ s/%%ProductID%%/$my_pid/ig;
    $my_box =~ s/\[\[itemID\]\]/$my_item_id/ig;
    $my_box =~ s/\[\[ProductID\]\]/$my_item_id/ig;
    $my_box =~ s/\[\[Qty\]\]/$qty/ig;

    return $my_box;
}

#######################################################################
#                     get_sc_ppinc_info Subroutine
#######################################################################
# form supplied PPINC will override defaults but not layout file set in category metatag manager.

sub get_sc_ppinc_info {
    local ( $my_ppinc, $my_ppinc_user_created, $the_whole_page, $keywords ) = q{};
    local ( $used_default ) = 0;
    my ( $test, $test2, $name ) = q{};

    if ( $sc_ppinc_info ) {  # no need to load it, already have it
        return $sc_ppinc_info;
    }

    $my_ppinc = "$sc_product_layouts_dir/$ppinc_root_name_orig";

    # finish building the ppinc file location
    if ( $form_data{'ppinc'} ) {
        $form_data{'ppinc'} =~ /([\w-_]+)/;
        $name = $1;
        $test = $my_ppinc . '-' . $name . '.inc';
    }


    if ( $meta_category_layout_found == 1 ) {
         # ppinc set in category metatag manager, set in stone: immutable
         $my_ppinc = "$sc_product_layouts_dir/$cat_layout";
    }
    elsif ( $sc_used_ppinc_category == 1 ) {
         # Legacy way to set the ppinc by using a file named after the category with underscores for spaces
         # ppinc is a physical file, however if set in category metatag mgr, then this is skipped.
         $my_ppinc = "$sc_product_layouts_dir/$ppinc_root_name.inc";
    }
    elsif ( -f $test ) {
        $my_ppinc = $test;
    }
    else {  # don't break! Just use default file
        $my_ppinc .= '.inc';
        $used_default = 1;
    }

    $sc_used_ppinc_category = q{};

    open( PAGE, "$my_ppinc" ) || file_open_error( "$sc_cart_path", "get ppinc -- $my_ppinc",__FILE__, __LINE__ );
    read( PAGE, $the_whole_page, 102400 ) ;  # 100K max size! Should be just a few K
    close PAGE;

    ( $very_first_part, $the_whole_page, $junk ) = split( /<h3>--$cut_here_div--<\/h3>/i, $the_whole_page, 3 );
    if ( $the_whole_page eq '' ) {
        $the_whole_page = $very_first_part;
    }

    if ( ( $sc_debug_mode =~ /yes/i ) && ( $used_default == 1 ) ) {
        $the_whole_page = "<!-- Used Default, $orig_ppinc not found. -->\n" . $the_whole_page;
    }

    $sc_ppinc_info = $the_whole_page;    # save for next time
    $last_ppinc_name = $my_ppinc;
    return $sc_ppinc_info;

}

#######################################################################
#                    display_products_for_sale
#######################################################################
#
# display_products_for_sale is used to generate
# dynamically the "product pages" that the client will
# want to browse through.  There are two cases within it
# however.
#
# Firstly, if the store is an HTML-based store, this
# routine will either display the requested page
# or, in the case of a search, perform a search on all the
# pages in the store for the submitted keyword.
#
# Secondly, if this is a database-based store, the script
# will use the create_html_page_from_db to output the
# product page requested or to perform the search on the
# database.
#
# The subroutine takes no arguments and is called with the
# following syntax:
#
# display_products_for_sale();
#
#######################################################################

sub display_products_for_sale {

    # The script first determines which type of store this is.
    # If it turns out to be an HTML-based store, the script
    # will check to see if the current request is a keyword
    # search or simply a request to display a page.  If it is
    # a keyword search, the script will require the html
    # search library and use the html_search subroutine with
    # in it to perform the search.
    if ( ( $sc_use_html_product_pages eq 'yes' )
        || ( ( $sc_use_html_product_pages eq "$sc_maybe" ) && ( $page ) )
      )
    {

        if ( ( $search_request ) && ( $sc_use_html_product_pages eq 'yes' ) )  {
            standard_page_header('Search Results');
            require "$sc_html_search_routines_library_path";
            html_search();
            html_search_page_footer();
            call_exit();
        }

        # If the store is HTML-based and there is no current
        # keyword however, the script simply displays the page as
        # requested with display_page which will be discussed
        # shortly.
        display_page(
            "$sc_html_product_directory_path/$page", 'Display Products for Sale',__FILE__, __LINE__
        );
    }

    # On the other hand, if $sc_use_html_product_pages was set to
    # no, it means that the admin wants the script to generate
    # HTML product pages on the fly using the format string
    # and the raw database rows.  The script will do so
    # using the create_html_page_from_db subroutine which will
    # be discussed next.
    else {
        create_html_page_from_db();
    }

}

#######################################################################

1;
